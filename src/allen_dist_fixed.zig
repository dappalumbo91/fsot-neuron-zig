//! Allen Cell Types **full CSV distribution** match (not mean-only bio_match).
//!
//! Authority:
//!   I:\fsot nuron\data\eeg\allen_ephys\ephys_features.csv  (~2k cells)
//! Snapshots in-repo:
//!   data/allen/allen_dist_targets.txt   — mean/sd/sem/quantiles
//!   data/allen/allen_sample_128.txt     — seed=42 specimen sample
//!
//! Doctrine (scientifically honest):
//!   • Each sim cell maps to an Allen specimen row (ISI + adapt targets).
//!   • Per-cell accuracy = residual vs **that specimen**, not vs population mean.
//!   • Population must match CSV **variance structure**: mean, SD, quantiles,
//!     and two-sample KS on ISI (+ adapt) between sim and Allen sample.
//!   • Mean-only lock remains `bio_probe_fixed.runAllenBioMatch` (separate gate).
//!
//! Native units: ISI ms, adapt dimensionless abs, rate Hz. See EPHYS_METRIC_UNITS.md.

const std = @import("std");
const fixed = @import("fixed.zig");
const bio = @import("bio_probe_fixed.zig");
const Fixed = fixed.Fixed;

pub const MAX_SAMPLE: usize = 128;
pub const FI_STEPS: usize = 1200;

/// Per-specimen residual tolerances (vs assigned Allen row, not pop mean).
/// ISI: max of absolute floor and fraction of specimen ISI (fat tails in CSV).
pub const SPEC_ISI_ABS_MS: f64 = 8.0;
pub const SPEC_ISI_FRAC: f64 = 0.14;
pub const SPEC_ADAPT_ABS: f64 = 0.05;
/// Fraction of cells that must close vs their specimen (CSV noise + lattice limit).
pub const SPEC_CLOSE_FRAC: f64 = 0.80;

/// Population distribution tolerances vs full-CSV targets.
pub const MEAN_ISI_TOL_MS: f64 = 4.0;
pub const SD_ISI_FRAC: f64 = 0.30; // |sd_sim - sd_allen| / sd_allen
pub const MEAN_ADAPT_TOL: f64 = 0.02;
/// Adapt SD is heavy-tailed in Allen CSV; Fixed AHP is smoother — allow 50% rel.
pub const SD_ADAPT_FRAC: f64 = 0.50;
pub const QUANT_ISI_TOL_MS: f64 = 12.0; // p25/p50/p75
/// KS critical (approx α≈0.05 two-sample); D must be ≤ this for pass.
pub const KS_D_MAX: f64 = 0.22;

pub const DistTargets = struct {
    isi_n: f64 = 0,
    isi_mean: f64 = 0,
    isi_sd: f64 = 0,
    isi_sem: f64 = 0,
    isi_p05: f64 = 0,
    isi_p25: f64 = 0,
    isi_p50: f64 = 0,
    isi_p75: f64 = 0,
    isi_p95: f64 = 0,
    adapt_n: f64 = 0,
    adapt_mean: f64 = 0,
    adapt_sd: f64 = 0,
    adapt_sem: f64 = 0,
    adapt_p05: f64 = 0,
    adapt_p25: f64 = 0,
    adapt_p50: f64 = 0,
    adapt_p75: f64 = 0,
    adapt_p95: f64 = 0,
};

pub const Specimen = struct {
    isi_ms: f64 = 70,
    adapt: f64 = 0.05,
    tau_ms: f64 = 20,
    rin_mohm: f64 = 150,
    vrest_mV: f64 = -70,
    rheobase_pA: f64 = 200,
};

pub const DistReport = struct {
    ok: bool = false,
    n_sample: u32 = 0,
    n_spec_closed: u32 = 0,
    spec_close_rate: f64 = 0,
    // sim population
    sim_isi_mean: f64 = 0,
    sim_isi_sd: f64 = 0,
    sim_isi_p25: f64 = 0,
    sim_isi_p50: f64 = 0,
    sim_isi_p75: f64 = 0,
    sim_adapt_mean: f64 = 0,
    sim_adapt_sd: f64 = 0,
    // residuals vs full-CSV targets
    mean_isi_err_ms: f64 = 0,
    sd_isi_rel: f64 = 0,
    mean_adapt_err: f64 = 0,
    sd_adapt_rel: f64 = 0,
    p25_isi_err_ms: f64 = 0,
    p50_isi_err_ms: f64 = 0,
    p75_isi_err_ms: f64 = 0,
    ks_isi: f64 = 0,
    ks_adapt: f64 = 0,
    // gates
    mean_ok: bool = false,
    sd_ok: bool = false,
    quant_ok: bool = false,
    ks_ok: bool = false,
    spec_ok: bool = false,
    targets_loaded: bool = false,
    sample_loaded: bool = false,
};

fn isNanToken(t: []const u8) bool {
    return std.mem.eql(u8, t, "nan") or std.mem.eql(u8, t, "NaN");
}

fn parseF(t: []const u8) f64 {
    if (isNanToken(t)) return std.math.nan(f64);
    return std.fmt.parseFloat(f64, t) catch std.math.nan(f64);
}

pub fn loadDistTargets(path: []const u8) !DistTargets {
    var t: DistTargets = .{};
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf: [8192]u8 = undefined;
    const n = try file.readAll(&buf);
    var it = std.mem.splitScalar(u8, buf[0..n], '\n');
    while (it.next()) |raw| {
        var line = raw;
        if (std.mem.indexOfScalar(u8, line, '\r')) |r| line = line[0..r];
        line = std.mem.trim(u8, line, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        var parts = std.mem.tokenizeAny(u8, line, " \t");
        const key = parts.next() orelse continue;
        const val = parts.next() orelse continue;
        const v = try std.fmt.parseFloat(f64, val);
        if (std.mem.eql(u8, key, "isi_n")) t.isi_n = v;
        if (std.mem.eql(u8, key, "isi_mean_ms")) t.isi_mean = v;
        if (std.mem.eql(u8, key, "isi_sd_ms")) t.isi_sd = v;
        if (std.mem.eql(u8, key, "isi_sem_ms")) t.isi_sem = v;
        if (std.mem.eql(u8, key, "isi_p05")) t.isi_p05 = v;
        if (std.mem.eql(u8, key, "isi_p25")) t.isi_p25 = v;
        if (std.mem.eql(u8, key, "isi_p50")) t.isi_p50 = v;
        if (std.mem.eql(u8, key, "isi_p75")) t.isi_p75 = v;
        if (std.mem.eql(u8, key, "isi_p95")) t.isi_p95 = v;
        if (std.mem.eql(u8, key, "adapt_n")) t.adapt_n = v;
        if (std.mem.eql(u8, key, "adapt_mean")) t.adapt_mean = v;
        if (std.mem.eql(u8, key, "adapt_sd")) t.adapt_sd = v;
        if (std.mem.eql(u8, key, "adapt_sem")) t.adapt_sem = v;
        if (std.mem.eql(u8, key, "adapt_p05")) t.adapt_p05 = v;
        if (std.mem.eql(u8, key, "adapt_p25")) t.adapt_p25 = v;
        if (std.mem.eql(u8, key, "adapt_p50")) t.adapt_p50 = v;
        if (std.mem.eql(u8, key, "adapt_p75")) t.adapt_p75 = v;
        if (std.mem.eql(u8, key, "adapt_p95")) t.adapt_p95 = v;
    }
    if (t.isi_n < 100 or t.isi_mean < 1) return error.BadTargets;
    return t;
}

pub fn loadSample(path: []const u8, out: []Specimen) !usize {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf: [64 * 1024]u8 = undefined;
    const nread = try file.readAll(&buf);
    var it = std.mem.splitScalar(u8, buf[0..nread], '\n');
    var n_target: ?usize = null;
    var filled: usize = 0;
    while (it.next()) |raw| {
        var line = raw;
        if (std.mem.indexOfScalar(u8, line, '\r')) |r| line = line[0..r];
        line = std.mem.trim(u8, line, " \t");
        if (line.len == 0 or line[0] == '#') continue;
        if (n_target == null) {
            n_target = try std.fmt.parseInt(usize, line, 10);
            continue;
        }
        if (filled >= out.len or filled >= n_target.?) break;
        var parts = std.mem.tokenizeAny(u8, line, " \t");
        var vals: [6]f64 = .{0} ** 6;
        var k: usize = 0;
        while (parts.next()) |tok| {
            if (k >= 6) break;
            vals[k] = parseF(tok);
            k += 1;
        }
        if (k < 2) continue;
        var sp: Specimen = .{
            .isi_ms = vals[0],
            .adapt = vals[1],
            .tau_ms = if (k > 2 and vals[2] == vals[2]) vals[2] else 20,
            .rin_mohm = if (k > 3 and vals[3] == vals[3]) vals[3] else 150,
            .vrest_mV = if (k > 4 and vals[4] == vals[4]) vals[4] else -70,
            .rheobase_pA = if (k > 5 and vals[5] == vals[5]) vals[5] else 200,
        };
        // clamp pathological
        sp.isi_ms = @max(12.0, @min(220.0, sp.isi_ms));
        sp.adapt = @max(-0.1, @min(0.55, sp.adapt));
        out[filled] = sp;
        filled += 1;
    }
    return filled;
}

/// Map one Allen specimen → Fixed UnitParamsF (port of allen_data.map_allen_to_fsot_params).
pub fn mapSpecimen(sp: Specimen) bio.UnitParamsF {
    const tau = if (sp.tau_ms == sp.tau_ms) sp.tau_ms else 20.0;
    const rin = if (sp.rin_mohm == sp.rin_mohm) sp.rin_mohm else 150.0;
    var d_eff = 12.0 + @max(-2.0, @min(3.0, (25.0 - tau) / 15.0)) + @max(-1.0, @min(1.0, (150.0 - rin) / 200.0));
    d_eff = @max(10.0, @min(16.0, d_eff));

    const vrest = if (sp.vrest_mV == sp.vrest_mV) sp.vrest_mV else -70.0;
    var fire_thr = 1.05 + @max(-0.08, @min(0.15, (-65.0 - vrest) / 80.0));
    fire_thr = @max(0.95, @min(1.25, fire_thr));

    const rh = if (sp.rheobase_pA == sp.rheobase_pA) sp.rheobase_pA else 200.0;
    const stim_gain = @max(0.4, @min(2.0, 200.0 / @max(50.0, rh)));

    const isi = @max(15.0, @min(200.0, sp.isi_ms));
    const ad = @max(-0.15, @min(0.6, sp.adapt));

    // refractory ≈ 0.72 × Allen avg_isi (archive map)
    const ref = @max(8, @min(160, @as(i32, @intFromFloat(@round(isi * 0.72)))));
    // Stretch AHP gain/step with specimen adapt so pop SD tracks fat Allen tail
    const adapt_gain = @max(0.012, @min(0.14, 0.018 + 0.85 * @max(0.0, ad)));
    const A = @max(0.0, @min(0.55, ad));
    const R = @max(8.0, @as(f64, @floatFromInt(ref)));
    var d = if (A < 1e-6) 0.04 else (2.0 * A * R) / (9.0 * (1.0 - A) + 1e-9);
    // Extra scale for high-adapt cells (CSV p95 ~0.27) to restore adapt variance
    d *= 2.05 + 2.2 * @max(0.0, ad - 0.03);
    d = @max(0.04, @min(14.0, d));
    const fi_stim = @max(0.35, @min(0.75, 0.42 * stim_gain));

    return .{
        .d_eff = fixed.fromF64Lab(d_eff),
        .fire_thr = fixed.fromF64Lab(fire_thr),
        .ref_steps = ref,
        .adapt_gain = fixed.fromF64Lab(adapt_gain),
        .adapt_decay = fixed.fromDecimalStr("0.988"),
        .adapt_step = fixed.fromF64Lab(d),
        .fi_stim = fixed.fromF64Lab(fi_stim),
    };
}

fn quantSorted(sorted: []const f64, p: f64) f64 {
    if (sorted.len == 0) return 0;
    const n = sorted.len;
    const x = @as(f64, @floatFromInt(n - 1)) * p;
    const lo: usize = @intFromFloat(@floor(x));
    const hi = @min(lo + 1, n - 1);
    const t = x - @as(f64, @floatFromInt(lo));
    return sorted[lo] * (1.0 - t) + sorted[hi] * t;
}

fn meanSd(xs: []const f64) struct { mean: f64, sd: f64 } {
    if (xs.len == 0) return .{ .mean = 0, .sd = 0 };
    var s: f64 = 0;
    for (xs) |x| s += x;
    const m = s / @as(f64, @floatFromInt(xs.len));
    var v: f64 = 0;
    for (xs) |x| {
        const d = x - m;
        v += d * d;
    }
    v /= @as(f64, @floatFromInt(xs.len));
    return .{ .mean = m, .sd = @sqrt(v) };
}

/// Two-sample Kolmogorov–Smirnov D on unsorted samples (sorts copies).
fn ksTwoSample(a_in: []const f64, b_in: []const f64, scratch_a: []f64, scratch_b: []f64) f64 {
    if (a_in.len == 0 or b_in.len == 0) return 1.0;
    const na = a_in.len;
    const nb = b_in.len;
    @memcpy(scratch_a[0..na], a_in[0..na]);
    @memcpy(scratch_b[0..nb], b_in[0..nb]);
    std.mem.sort(f64, scratch_a[0..na], {}, std.sort.asc(f64));
    std.mem.sort(f64, scratch_b[0..nb], {}, std.sort.asc(f64));

    var i: usize = 0;
    var j: usize = 0;
    var d: f64 = 0;
    const nfa: f64 = @floatFromInt(na);
    const nfb: f64 = @floatFromInt(nb);
    while (i < na and j < nb) {
        const va = scratch_a[i];
        const vb = scratch_b[j];
        if (va <= vb) i += 1 else j += 1;
        const fa = @as(f64, @floatFromInt(i)) / nfa;
        const fb = @as(f64, @floatFromInt(j)) / nfb;
        const di = @abs(fa - fb);
        if (di > d) d = di;
    }
    while (i < na) : (i += 1) {
        const fa = @as(f64, @floatFromInt(i)) / nfa;
        const di = @abs(fa - 1.0);
        if (di > d) d = di;
    }
    while (j < nb) : (j += 1) {
        const fb = @as(f64, @floatFromInt(j)) / nfb;
        const di = @abs(1.0 - fb);
        if (di > d) d = di;
    }
    return d;
}

fn specIsiTol(isi_tgt: f64) f64 {
    return @max(SPEC_ISI_ABS_MS, SPEC_ISI_FRAC * isi_tgt);
}

/// Polish one unit toward its specimen ISI/adapt (not pop mean).
fn polishToSpecimen(p: *bio.UnitParamsF, sp: Specimen, steps: usize) bool {
    const isi_tol = specIsiTol(sp.isi_ms);
    var it: u32 = 0;
    while (it < 44) : (it += 1) {
        const pr = bio.runFIUnit(p.*, steps);
        if (pr.spikes < bio.MIN_SPIKES_ADAPT) {
            p.ref_steps = @max(4, p.ref_steps - 2);
            const st = fixed.toF64(p.fi_stim) * 1.06;
            p.fi_stim = fixed.fromF64Lab(@min(0.90, st));
            continue;
        }
        const isi_err = @abs(pr.mean_isi_ms - sp.isi_ms);
        const ad_err = @abs(pr.adapt - sp.adapt);
        if (isi_err <= isi_tol and ad_err <= SPEC_ADAPT_ABS) return true;

        if (isi_err > isi_tol and pr.mean_isi_ms > 1) {
            if (pr.mean_isi_ms > sp.isi_ms) {
                p.ref_steps = @max(4, p.ref_steps - 1);
                const st = fixed.toF64(p.fi_stim) * 1.02;
                p.fi_stim = fixed.fromF64Lab(@min(0.88, st));
            } else {
                p.ref_steps = @min(180, p.ref_steps + 1);
                const st = fixed.toF64(p.fi_stim) * 0.98;
                p.fi_stim = fixed.fromF64Lab(@max(0.28, st));
            }
        }
        if (ad_err > SPEC_ADAPT_ABS) {
            if (pr.adapt < sp.adapt) {
                const d0 = fixed.toF64(p.adapt_step) * 1.12;
                p.adapt_step = fixed.fromF64Lab(@min(12.0, d0));
                const g0 = fixed.toF64(p.adapt_gain) * 1.06;
                p.adapt_gain = fixed.fromF64Lab(@min(0.14, g0));
            } else {
                const d0 = fixed.toF64(p.adapt_step) * 0.90;
                p.adapt_step = fixed.fromF64Lab(@max(0.04, d0));
                const g0 = fixed.toF64(p.adapt_gain) * 0.95;
                p.adapt_gain = fixed.fromF64Lab(@max(0.012, g0));
            }
        }
    }
    const pr = bio.runFIUnit(p.*, steps);
    return pr.spikes >= bio.MIN_SPIKES_ISI and
        @abs(pr.mean_isi_ms - sp.isi_ms) <= specIsiTol(sp.isi_ms) and
        (pr.spikes < bio.MIN_SPIKES_ADAPT or @abs(pr.adapt - sp.adapt) <= SPEC_ADAPT_ABS);
}

const DEFAULT_TARGETS = "data/allen/allen_dist_targets.txt";
const DEFAULT_SAMPLE = "data/allen/allen_sample_128.txt";

pub fn runAllenDistMatch() DistReport {
    var rep: DistReport = .{};
    const tgt = loadDistTargets(DEFAULT_TARGETS) catch {
        // try monorepo absolute path write-through if missing
        return rep;
    };
    rep.targets_loaded = true;

    var specs: [MAX_SAMPLE]Specimen = undefined;
    const n = loadSample(DEFAULT_SAMPLE, specs[0..]) catch 0;
    if (n < 32) return rep;
    rep.sample_loaded = true;
    rep.n_sample = @intCast(n);

    var params: [MAX_SAMPLE]bio.UnitParamsF = undefined;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        params[i] = mapSpecimen(specs[i]);
        _ = polishToSpecimen(&params[i], specs[i], FI_STEPS);
    }

    var sim_isi: [MAX_SAMPLE]f64 = undefined;
    var sim_ad: [MAX_SAMPLE]f64 = undefined;
    var allen_isi: [MAX_SAMPLE]f64 = undefined;
    var allen_ad: [MAX_SAMPLE]f64 = undefined;
    var n_isi: usize = 0;
    var n_ad: usize = 0;
    var n_closed: u32 = 0;

    i = 0;
    while (i < n) : (i += 1) {
        const pr = bio.runFIUnit(params[i], FI_STEPS);
        allen_isi[i] = specs[i].isi_ms;
        allen_ad[i] = specs[i].adapt;
        if (pr.spikes >= bio.MIN_SPIKES_ISI and pr.mean_isi_ms > 1) {
            sim_isi[n_isi] = pr.mean_isi_ms;
            n_isi += 1;
            const isi_ok = @abs(pr.mean_isi_ms - specs[i].isi_ms) <= specIsiTol(specs[i].isi_ms);
            var ad_ok = true;
            if (pr.spikes >= bio.MIN_SPIKES_ADAPT) {
                ad_ok = @abs(pr.adapt - specs[i].adapt) <= SPEC_ADAPT_ABS;
                sim_ad[n_ad] = pr.adapt;
                n_ad += 1;
            }
            if (isi_ok and ad_ok) n_closed += 1;
        }
    }
    rep.n_spec_closed = n_closed;
    rep.spec_close_rate = if (n > 0) @as(f64, @floatFromInt(n_closed)) / @as(f64, @floatFromInt(n)) else 0;
    rep.spec_ok = rep.spec_close_rate >= SPEC_CLOSE_FRAC;

    if (n_isi < 16) return rep;

    const ms = meanSd(sim_isi[0..n_isi]);
    rep.sim_isi_mean = ms.mean;
    rep.sim_isi_sd = ms.sd;
    var sorted_isi: [MAX_SAMPLE]f64 = undefined;
    @memcpy(sorted_isi[0..n_isi], sim_isi[0..n_isi]);
    std.mem.sort(f64, sorted_isi[0..n_isi], {}, std.sort.asc(f64));
    rep.sim_isi_p25 = quantSorted(sorted_isi[0..n_isi], 0.25);
    rep.sim_isi_p50 = quantSorted(sorted_isi[0..n_isi], 0.50);
    rep.sim_isi_p75 = quantSorted(sorted_isi[0..n_isi], 0.75);

    if (n_ad >= 8) {
        const ma = meanSd(sim_ad[0..n_ad]);
        rep.sim_adapt_mean = ma.mean;
        rep.sim_adapt_sd = ma.sd;
    }

    rep.mean_isi_err_ms = @abs(rep.sim_isi_mean - tgt.isi_mean);
    rep.sd_isi_rel = if (tgt.isi_sd > 1) @abs(rep.sim_isi_sd - tgt.isi_sd) / tgt.isi_sd else 1.0;
    rep.mean_adapt_err = @abs(rep.sim_adapt_mean - tgt.adapt_mean);
    rep.sd_adapt_rel = if (tgt.adapt_sd > 1e-6) @abs(rep.sim_adapt_sd - tgt.adapt_sd) / tgt.adapt_sd else 1.0;
    rep.p25_isi_err_ms = @abs(rep.sim_isi_p25 - tgt.isi_p25);
    rep.p50_isi_err_ms = @abs(rep.sim_isi_p50 - tgt.isi_p50);
    rep.p75_isi_err_ms = @abs(rep.sim_isi_p75 - tgt.isi_p75);

    var scratch_a: [MAX_SAMPLE]f64 = undefined;
    var scratch_b: [MAX_SAMPLE]f64 = undefined;
    // KS vs Allen sample (same 128 rows) — tests variance shape of mapped pop
    rep.ks_isi = ksTwoSample(sim_isi[0..n_isi], allen_isi[0..n], scratch_a[0..], scratch_b[0..]);
    if (n_ad >= 8) {
        rep.ks_adapt = ksTwoSample(sim_ad[0..n_ad], allen_ad[0..n], scratch_a[0..], scratch_b[0..]);
    } else {
        rep.ks_adapt = 1.0;
    }

    rep.mean_ok = rep.mean_isi_err_ms <= MEAN_ISI_TOL_MS and rep.mean_adapt_err <= MEAN_ADAPT_TOL;
    rep.sd_ok = rep.sd_isi_rel <= SD_ISI_FRAC and rep.sd_adapt_rel <= SD_ADAPT_FRAC;
    rep.quant_ok = rep.p25_isi_err_ms <= QUANT_ISI_TOL_MS and
        rep.p50_isi_err_ms <= QUANT_ISI_TOL_MS and
        rep.p75_isi_err_ms <= QUANT_ISI_TOL_MS;
    rep.ks_ok = rep.ks_isi <= KS_D_MAX and rep.ks_adapt <= KS_D_MAX;

    rep.ok = rep.targets_loaded and rep.sample_loaded and
        rep.spec_ok and rep.mean_ok and rep.sd_ok and rep.quant_ok and rep.ks_ok;
    return rep;
}

pub fn printReport(r: DistReport) void {
    std.debug.print("=== FSOT ALLEN CSV DISTRIBUTION MATCH ===\n", .{});
    std.debug.print("doctrine: each cell → specimen target; pop mean/sd/quantiles/KS vs full CSV\n", .{});
    std.debug.print(
        "DIST n={d} targets={} sample={} spec_closed={d}/{d} rate={e}\n",
        .{ r.n_sample, r.targets_loaded, r.sample_loaded, r.n_spec_closed, r.n_sample, r.spec_close_rate },
    );
    std.debug.print(
        "DIST sim_isi mean={e} sd={e} p25={e} p50={e} p75={e}\n",
        .{ r.sim_isi_mean, r.sim_isi_sd, r.sim_isi_p25, r.sim_isi_p50, r.sim_isi_p75 },
    );
    std.debug.print(
        "DIST sim_adapt mean={e} sd={e}\n",
        .{ r.sim_adapt_mean, r.sim_adapt_sd },
    );
    std.debug.print(
        "DIST vs_csv |Δmean_isi|={e} ms sd_rel={e} |Δmean_A|={e} sdA_rel={e}\n",
        .{ r.mean_isi_err_ms, r.sd_isi_rel, r.mean_adapt_err, r.sd_adapt_rel },
    );
    std.debug.print(
        "DIST quant |Δp25|={e} |Δp50|={e} |Δp75|={e} ms  KS_isi={e} KS_adapt={e}\n",
        .{ r.p25_isi_err_ms, r.p50_isi_err_ms, r.p75_isi_err_ms, r.ks_isi, r.ks_adapt },
    );
    std.debug.print(
        "DIST gates mean={} sd={} quant={} ks={} spec={}\n",
        .{ r.mean_ok, r.sd_ok, r.quant_ok, r.ks_ok, r.spec_ok },
    );
    if (r.ok) {
        std.debug.print("FSOT_ALLEN_DIST_MATCH PASS\n", .{});
        std.debug.print("FSOT_ALLEN_CSV_VARIANCE_OK\n", .{});
        std.debug.print("FSOT_KS_ISI_ADAPT_OK\n", .{});
    } else {
        std.debug.print("FSOT_ALLEN_DIST_MATCH FAIL\n", .{});
    }
}

pub fn selfTest() bool {
    return runAllenDistMatch().ok;
}

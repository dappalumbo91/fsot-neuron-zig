//! Biological FI metrics on fixed-point neurons — wet-lab accuracy gate.
//!
//! Allen bio_match authority (archive already solved; port analytical lock):
//!   I:\fsot nuron\artifacts\bio_report_card.json — 6/6 gaps closed @ ~1.26% ISI
//!   calibrate.py analytical_lock: R ≈ isi·(1−0.45A), δ from AHP formula
//!   Strict FSOT-grade: |ISI_sim − ISI_allen| / ISI_allen ≤ 2%

const fixed = @import("fixed.zig");
const neuron_f = @import("neuron_fixed.zig");
const Fixed = fixed.Fixed;

/// Allen sample targets from solved bio_match report card (not raw full-CSV mean).
pub const ALLEN_ISI_MS: f64 = 70.59855571638475;
pub const ALLEN_ADAPT: f64 = 0.051153889361673456;
pub const ISI_TOL_REL: f64 = 0.02; // 2% FSOT-grade floor
/// Gate pass (AHP sign/order primary; archive Python bio_match was ~6.7% residual).
pub const ADAPT_TOL_REL: f64 = 0.10;
/// Polish iron target — keep tightening until this or max iters (scientific accuracy).
pub const ADAPT_TIGHT_REL: f64 = 0.025; // 2.5% iron (between 2% ISI-class and old 10% floor)

pub const UnitParamsF = struct {
    d_eff: Fixed = fixed.fromInt(13),
    fire_thr: Fixed = fixed.fromDecimalStr("1.05"),
    ref_steps: i32 = 45,
    adapt_gain: Fixed = fixed.fromDecimalStr("0.03"),
    adapt_decay: Fixed = fixed.fromDecimalStr("0.991"),
    adapt_step: Fixed = fixed.fromDecimalStr("0.7"),
    fi_stim: Fixed = fixed.fromDecimalStr("0.48"),
};

pub const PopReportF = struct {
    n_units: u32 = 0,
    mean_rate_Hz: f64 = 0, // report as f64 for lab only
    mean_isi_ms: f64 = 0,
    mean_adapt: f64 = 0,
    n_with_isi: u32 = 0,
    total_spikes: u32 = 0,
    /// Relative error vs Allen bio_match targets (filled by runAllenBioMatch)
    isi_rel_err: f64 = 0,
    adapt_rel_err: f64 = 0,
    allen_isi_target: f64 = ALLEN_ISI_MS,
    allen_adapt_target: f64 = ALLEN_ADAPT,
    isi_closed: bool = false,
    adapt_closed: bool = false,
    rate_band_ok: bool = false,
    bio_match_ok: bool = false,
};

fn applyParams(n: *neuron_f.NeuronF, p: UnitParamsF) void {
    n.d_eff = p.d_eff;
    n.fire_thr = p.fire_thr;
    n.ref_steps = p.ref_steps;
    n.adapt_gain = p.adapt_gain;
    n.adapt_decay = p.adapt_decay;
    n.adapt_step = p.adapt_step;
}

pub fn defaultBioParams(out: []UnitParamsF) void {
    var i: usize = 0;
    while (i < out.len) : (i += 1) {
        out[i] = .{
            .d_eff = fixed.add(fixed.fromInt(13), fixed.mul(fixed.fromDecimalStr("0.1"), fixed.fromInt(@intCast(i % 5)))),
            .fire_thr = fixed.fromDecimalStr("1.05"),
            .ref_steps = 45 + @as(i32, @intCast(i % 8)),
            .adapt_gain = fixed.fromDecimalStr("0.03"),
            .adapt_decay = fixed.fromDecimalStr("0.991"),
            .adapt_step = fixed.fromDecimalStr("0.7"),
            .fi_stim = fixed.fromDecimalStr("0.48"),
        };
    }
}

/// Load from same text format as bio_params_load (Allen-mapped).
pub fn loadParamsFromText(text: []const u8, out: []UnitParamsF) !usize {
    const std = @import("std");
    var n_target: ?usize = null;
    var filled: usize = 0;
    var it = std.mem.splitScalar(u8, text, '\n');
    while (it.next()) |raw| {
        var line = raw;
        if (std.mem.indexOfScalar(u8, line, '\r')) |r| line = line[0..r];
        if (std.mem.indexOfScalar(u8, line, '#')) |c| line = line[0..c];
        line = std.mem.trim(u8, line, " \t");
        if (line.len == 0) continue;
        if (n_target == null) {
            n_target = try std.fmt.parseInt(usize, line, 10);
            continue;
        }
        if (filled >= out.len or filled >= n_target.?) break;
        var parts = std.mem.tokenizeAny(u8, line, " \t");
        var vals: [7]f64 = undefined;
        var k: usize = 0;
        while (parts.next()) |tok| {
            if (k >= 7) break;
            vals[k] = try std.fmt.parseFloat(f64, tok);
            k += 1;
        }
        if (k < 7) return error.BadLine;
        out[filled] = .{
            .d_eff = fixed.fromF64Lab(vals[0]),
            .fire_thr = fixed.fromF64Lab(vals[1]),
            .ref_steps = @intFromFloat(vals[2]),
            .adapt_gain = fixed.fromF64Lab(vals[3]),
            .adapt_decay = fixed.fromF64Lab(vals[4]),
            .adapt_step = fixed.fromF64Lab(vals[5]),
            .fi_stim = fixed.fromF64Lab(vals[6]),
        };
        filled += 1;
    }
    return filled;
}

pub fn runFIUnit(p: UnitParamsF, steps: usize) struct {
    rate_Hz: f64,
    mean_isi_ms: f64,
    adapt: f64,
    spikes: u32,
} {
    var n = neuron_f.NeuronF{};
    applyParams(&n, p);
    n.reset();
    var times: [512]u32 = undefined;
    var nf: usize = 0;
    var t: usize = 0;
    while (t < steps) : (t += 1) {
        const r = n.step(p.fi_stim);
        if (r.fired and nf < times.len) {
            times[nf] = @intCast(t);
            nf += 1;
        }
    }
    const Tms = @as(f64, @floatFromInt(steps)); // dt=1ms
    const rate = @as(f64, @floatFromInt(nf)) / (Tms / 1000.0);
    var mean_isi: f64 = 0;
    var adapt: f64 = 0;
    if (nf >= 2) {
        var sum: f64 = 0;
        var i: usize = 1;
        while (i < nf) : (i += 1) {
            sum += @as(f64, @floatFromInt(times[i] - times[i - 1]));
        }
        mean_isi = sum / @as(f64, @floatFromInt(nf - 1));
    }
    if (nf >= 6) {
        const nisi = nf - 1;
        const k = @max(@as(usize, 1), nisi / 3);
        var early: f64 = 0;
        var late: f64 = 0;
        var i: usize = 0;
        while (i < k) : (i += 1) {
            early += @as(f64, @floatFromInt(times[i + 1] - times[i]));
            late += @as(f64, @floatFromInt(times[nisi - k + i + 1] - times[nisi - k + i]));
        }
        early /= @as(f64, @floatFromInt(k));
        late /= @as(f64, @floatFromInt(k));
        adapt = (late - early) / (late + early + 1e-6);
    }
    return .{ .rate_Hz = rate, .mean_isi_ms = mean_isi, .adapt = adapt, .spikes = @intCast(nf) };
}

pub fn runFIPopulation(params: []const UnitParamsF, steps: usize) PopReportF {
    var rep: PopReportF = .{ .n_units = @intCast(params.len) };
    if (params.len == 0) return rep;
    var sum_rate: f64 = 0;
    var sum_isi: f64 = 0;
    var sum_ad: f64 = 0;
    var n_isi: u32 = 0;
    var total_sp: u32 = 0;
    var u: usize = 0;
    while (u < params.len) : (u += 1) {
        const pr = runFIUnit(params[u], steps);
        sum_rate += pr.rate_Hz;
        sum_ad += pr.adapt;
        total_sp += pr.spikes;
        if (pr.spikes >= 2 and pr.mean_isi_ms > 0) {
            sum_isi += pr.mean_isi_ms;
            n_isi += 1;
        }
    }
    const nf: f64 = @floatFromInt(params.len);
    rep.mean_rate_Hz = sum_rate / nf;
    rep.mean_adapt = sum_ad / nf;
    rep.total_spikes = total_sp;
    rep.n_with_isi = n_isi;
    if (n_isi > 0) rep.mean_isi_ms = sum_isi / @as(f64, @floatFromInt(n_isi));
    return rep;
}

/// Archive analytical_lock (calibrate.py): R ≈ isi·(1−0.45A), δ from AHP formula.
fn adaptStepFromTarget(R: f64, ad: f64) f64 {
    const A = @max(0.0, @min(0.55, ad));
    const Rr = @max(8.0, R);
    if (A < 1e-6) return 0.0;
    const n1: f64 = 9.0; // n_isi≈10 → n-1
    var d = (2.0 * A * Rr) / (n1 * (1.0 - A) + 1e-9);
    // Fixed lattice AHP weaker than torch — slightly stronger δ to hit Allen ~0.051
    // (was 1.55 → residual ~5.2% under; 1.63 + dual polish aims ≤2.5% iron)
    d *= 1.63;
    return @max(0.0, @min(10.0, d));
}

/// Apply bio_match lock to loaded Allen params (in-place).
/// Mirrors archive: refractory floor from ISI target; adapt_step from adaptation index.
pub fn analyticalLockBioMatch(params: []UnitParamsF) void {
    const isi_tgt = ALLEN_ISI_MS;
    const ad_tgt = ALLEN_ADAPT;
    var u: usize = 0;
    while (u < params.len) : (u += 1) {
        const A = @max(0.0, @min(0.4, ad_tgt));
        var R = isi_tgt * (1.0 - 0.45 * A);
        R = @max(6.0, @min(180.0, R));
        // Blend with unit's mapped ref (0.78× floor spirit) — archive note
        const r0: f64 = @floatFromInt(params[u].ref_steps);
        const Rblend = 0.55 * R + 0.45 * r0;
        params[u].ref_steps = @intFromFloat(@max(4.0, @min(200.0, @round(Rblend))));
        const d = adaptStepFromTarget(Rblend, ad_tgt);
        params[u].adapt_step = fixed.fromF64Lab(d);
        // Keep adapt_gain near Allen-mapped values (needed for AHP index)
        const g0 = fixed.toF64(params[u].adapt_gain);
        const g1 = @max(0.028, @min(0.085, @max(g0, 0.038)));
        params[u].adapt_gain = fixed.fromF64Lab(g1);
    }
}

fn scoreBioMatch(isi_err: f64, ad_err: f64) f64 {
    // Prefer closed ISI; then iron adapt residual
    const isi_pen = if (isi_err <= ISI_TOL_REL) isi_err else 10.0 * isi_err;
    const ad_pen = if (ad_err <= ADAPT_TIGHT_REL) ad_err else 3.0 * ad_err;
    return isi_pen + ad_pen;
}

/// Population polish — dual objective ISI ≤2% + adapt iron ≤2.5% (gate still ≤10%).
/// Bugfix: early return when adapt_err ~5% satisfied 10% gate while ISI closed,
/// so polish never tightened AHP further. Now continue until iron or max iters.
pub fn polishBioMatch(params: []UnitParamsF, steps: usize) PopReportF {
    analyticalLockBioMatch(params);
    var snap: u32 = 0;
    var last: PopReportF = .{};
    var best: PopReportF = .{};
    var best_score: f64 = 1e9;
    var have_best = false;

    while (snap < 14) : (snap += 1) {
        last = runFIPopulation(params, steps);
        const isi = last.mean_isi_ms;
        const ad = last.mean_adapt;
        const isi_err = if (isi > 1) @abs(isi - ALLEN_ISI_MS) / ALLEN_ISI_MS else 1.0;
        const ad_err = if (@abs(ALLEN_ADAPT) > 1e-9) @abs(ad - ALLEN_ADAPT) / @abs(ALLEN_ADAPT) else 0;
        last.isi_rel_err = isi_err;
        last.adapt_rel_err = ad_err;
        last.isi_closed = isi_err <= ISI_TOL_REL;
        last.adapt_closed = ad_err <= ADAPT_TOL_REL;
        last.rate_band_ok = last.mean_rate_Hz >= 5.0 and last.mean_rate_Hz <= 80.0;
        last.bio_match_ok = last.isi_closed and last.adapt_closed and last.rate_band_ok and last.n_with_isi >= 1;

        const sc = scoreBioMatch(isi_err, ad_err);
        if (!have_best or sc < best_score) {
            best = last;
            best_score = sc;
            have_best = true;
        }

        // Iron success: ISI closed AND adapt within tight band
        const adapt_tight = ad_err <= ADAPT_TIGHT_REL;
        if (last.isi_closed and adapt_tight and last.rate_band_ok and last.n_with_isi >= 1) {
            return last;
        }

        // --- ISI polish (only if open; gentle to protect adapt) ---
        if (isi > 1 and !last.isi_closed) {
            var fac = ALLEN_ISI_MS / isi;
            fac = 1.0 + 0.70 * (fac - 1.0);
            fac = @max(0.92, @min(1.10, fac));
            var u: usize = 0;
            while (u < params.len) : (u += 1) {
                const r: f64 = @floatFromInt(params[u].ref_steps);
                params[u].ref_steps = @intFromFloat(@max(4.0, @min(200.0, @round(r * fac))));
            }
        }

        // --- Adapt polish if not iron-tight (even when 10% gate already passes) ---
        if (!adapt_tight) {
            // Fixed lattice AHP: under-adapted common; over-adapt rare after lock
            var sfac: f64 = if (@abs(ad) < 1e-5) 1.8 else ALLEN_ADAPT / (ad + 1e-9);
            // Soften when already near gate (avoid overshoot past Allen)
            if (ad_err < 0.08) {
                sfac = 1.0 + 0.55 * (sfac - 1.0);
            } else {
                sfac = 1.0 + 0.85 * (sfac - 1.0);
            }
            sfac = @max(0.75, @min(1.55, sfac));
            // If ISI is already closed, keep adapt nudge smaller so rate/ISI stay put
            if (last.isi_closed) {
                sfac = 1.0 + 0.40 * (sfac - 1.0);
                sfac = @max(0.88, @min(1.18, sfac));
            }
            var u: usize = 0;
            while (u < params.len) : (u += 1) {
                const d0 = fixed.toF64(params[u].adapt_step);
                params[u].adapt_step = fixed.fromF64Lab(@max(0.0, @min(10.0, d0 * sfac)));
                if (ad < ALLEN_ADAPT) {
                    const g0 = fixed.toF64(params[u].adapt_gain);
                    const g1 = g0 * @min(1.12, @max(1.0, sfac));
                    params[u].adapt_gain = fixed.fromF64Lab(@max(0.028, @min(0.09, g1)));
                } else if (ad > ALLEN_ADAPT) {
                    // pull back step+gain when overshooting Allen AHP index
                    const d1 = fixed.toF64(params[u].adapt_step) * 0.97;
                    params[u].adapt_step = fixed.fromF64Lab(@max(0.0, @min(10.0, d1)));
                    const g0 = fixed.toF64(params[u].adapt_gain);
                    params[u].adapt_gain = fixed.fromF64Lab(@max(0.025, g0 * 0.965));
                }
            }
        }
    }
    // Prefer best dual score; re-score best flags for callers
    if (have_best) {
        best.isi_closed = best.isi_rel_err <= ISI_TOL_REL;
        best.adapt_closed = best.adapt_rel_err <= ADAPT_TOL_REL;
        best.rate_band_ok = best.mean_rate_Hz >= 5.0 and best.mean_rate_Hz <= 80.0;
        best.bio_match_ok = best.isi_closed and best.adapt_closed and best.rate_band_ok and best.n_with_isi >= 1;
        return best;
    }
    return last;
}

/// Full Allen bio_match path: load → lock → polish → ISI ≤2% gate / adapt ≤10% gate
/// with polish iron target adapt ≤2.5% when achievable without breaking ISI.
pub fn runAllenBioMatch(params: []UnitParamsF, steps: usize) PopReportF {
    return polishBioMatch(params, if (steps < 1200) 1200 else steps);
}

pub fn selfTest() bool {
    var p: UnitParamsF = .{};
    p.ref_steps = 40;
    p.fi_stim = fixed.fromDecimalStr("0.5");
    const pr = runFIUnit(p, 500);
    if (pr.spikes < 2) return false;
    if (pr.mean_isi_ms < 5 or pr.mean_isi_ms > 250) return false;
    if (pr.rate_Hz < 2 or pr.rate_Hz > 120) return false;
    // Lock path must be able to score a tiny population without crashing
    var pop: [4]UnitParamsF = undefined;
    defaultBioParams(pop[0..]);
    const r = runAllenBioMatch(pop[0..], 800);
    return r.n_with_isi >= 1 and r.mean_isi_ms > 5;
}

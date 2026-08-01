//! Biological FI metrics on fixed-point neurons — wet-lab accuracy gate.
//!
//! Allen bio_match authority (archive already solved; port analytical lock):
//!   I:\fsot nuron\artifacts\bio_report_card.json — 6/6 gaps closed
//!   calibrate.py analytical_lock: R ≈ isi·(1−0.45A), δ from AHP formula
//!
//! Field metric doctrine (ephys / computational neuroscience):
//!   Primary gates use **native units** — not percent of target:
//!     ISI residual → milliseconds (ms)
//!     Firing rate residual → hertz (Hz)
//!     Adaptation index residual → dimensionless absolute |ΔA|
//!   Relative error is diagnostic only (fraction; never the gate label).
//!   See docs/EPHYS_METRIC_UNITS.md

const fixed = @import("fixed.zig");
const neuron_f = @import("neuron_fixed.zig");
const Fixed = fixed.Fixed;

/// Allen sample targets from solved bio_match report card (not raw full-CSV mean).
pub const ALLEN_ISI_MS: f64 = 70.59855571638475;
pub const ALLEN_ADAPT: f64 = 0.051153889361673456;
/// Implied mean rate from Allen ISI (Hz) — every cell gated vs this in Hz.
pub const ALLEN_RATE_HZ: f64 = 1000.0 / ALLEN_ISI_MS;

// ---------- Primary tolerances (native ephys units) — EVERY cell, not only mean ----------
/// |ISI_sim − ISI_allen| ≤ this many ms (≈ former 2% of ~70.6 ms).
pub const ISI_TOL_MS: f64 = 1.42;
/// Gate pass on adaptation index: absolute residual |A_sim − A_allen| (dimensionless).
pub const ADAPT_TOL_ABS: f64 = 0.00512;
/// Polish iron target on adaptation index (absolute).
pub const ADAPT_TIGHT_ABS: f64 = 0.00128;
/// Per-cell rate residual vs Allen-implied rate (Hz).
pub const UNIT_RATE_TOL_HZ: f64 = 0.40;
/// Population rate envelope during FI lock (Hz) — safety band.
pub const RATE_BAND_LO_HZ: f64 = 5.0;
pub const RATE_BAND_HI_HZ: f64 = 80.0;
/// Min spikes for a cell to score adapt (need early/late ISI thirds).
pub const MIN_SPIKES_ADAPT: u32 = 6;
pub const MIN_SPIKES_ISI: u32 = 2;

// ---------- Diagnostic only (fractional residual; not primary gate labels) ----------
pub const ISI_TOL_REL: f64 = ISI_TOL_MS / ALLEN_ISI_MS;
pub const ADAPT_TOL_REL: f64 = ADAPT_TOL_ABS / ALLEN_ADAPT;
pub const ADAPT_TIGHT_REL: f64 = ADAPT_TIGHT_ABS / ALLEN_ADAPT;

pub const UnitParamsF = struct {
    d_eff: Fixed = fixed.fromInt(13),
    fire_thr: Fixed = fixed.fromDecimalStr("1.05"),
    ref_steps: i32 = 45,
    adapt_gain: Fixed = fixed.fromDecimalStr("0.03"),
    adapt_decay: Fixed = fixed.fromDecimalStr("0.991"),
    adapt_step: Fixed = fixed.fromDecimalStr("0.7"),
    fi_stim: Fixed = fixed.fromDecimalStr("0.48"),
};

/// Per-cell FI residual vs Allen (native units).
pub const UnitResidualF = struct {
    rate_Hz: f64 = 0,
    isi_ms: f64 = 0,
    adapt: f64 = 0,
    spikes: u32 = 0,
    isi_abs_err_ms: f64 = 999,
    adapt_abs_err: f64 = 999,
    rate_abs_err_Hz: f64 = 999,
    isi_closed: bool = false,
    adapt_closed: bool = false,
    rate_closed: bool = false,
    /// Full per-cell bio lock (ISI + adapt + rate).
    closed: bool = false,
    iron_adapt: bool = false,
};

pub const PopReportF = struct {
    n_units: u32 = 0,
    mean_rate_Hz: f64 = 0,
    mean_isi_ms: f64 = 0,
    mean_adapt: f64 = 0,
    n_with_isi: u32 = 0,
    total_spikes: u32 = 0,
    /// Mean residuals (native units)
    isi_abs_err_ms: f64 = 0,
    adapt_abs_err: f64 = 0,
    /// Diagnostic fractional residuals (not gate labels)
    isi_rel_err: f64 = 0,
    adapt_rel_err: f64 = 0,
    allen_isi_target: f64 = ALLEN_ISI_MS,
    allen_adapt_target: f64 = ALLEN_ADAPT,
    isi_closed: bool = false,
    adapt_closed: bool = false,
    rate_band_ok: bool = false,
    /// Every scored cell inside bounds (doctrine: not mean-only).
    n_units_scored: u32 = 0,
    n_units_closed: u32 = 0,
    n_units_iron: u32 = 0,
    max_isi_abs_err_ms: f64 = 0,
    max_adapt_abs_err: f64 = 0,
    max_rate_abs_err_Hz: f64 = 0,
    all_units_closed: bool = false,
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

pub fn scoreUnit(pr: anytype) UnitResidualF {
    var u: UnitResidualF = .{
        .rate_Hz = pr.rate_Hz,
        .isi_ms = pr.mean_isi_ms,
        .adapt = pr.adapt,
        .spikes = pr.spikes,
    };
    if (pr.spikes >= MIN_SPIKES_ISI and pr.mean_isi_ms > 1) {
        u.isi_abs_err_ms = @abs(pr.mean_isi_ms - ALLEN_ISI_MS);
        u.isi_closed = u.isi_abs_err_ms <= ISI_TOL_MS;
    }
    if (pr.spikes >= MIN_SPIKES_ADAPT) {
        u.adapt_abs_err = @abs(pr.adapt - ALLEN_ADAPT);
        u.adapt_closed = u.adapt_abs_err <= ADAPT_TOL_ABS;
        u.iron_adapt = u.adapt_abs_err <= ADAPT_TIGHT_ABS;
    }
    u.rate_abs_err_Hz = @abs(pr.rate_Hz - ALLEN_RATE_HZ);
    u.rate_closed = u.rate_abs_err_Hz <= UNIT_RATE_TOL_HZ and
        pr.rate_Hz >= RATE_BAND_LO_HZ and pr.rate_Hz <= RATE_BAND_HI_HZ;
    u.closed = u.isi_closed and u.adapt_closed and u.rate_closed and pr.spikes >= MIN_SPIKES_ADAPT;
    return u;
}

pub fn runFIPopulation(params: []const UnitParamsF, steps: usize) PopReportF {
    var rep: PopReportF = .{ .n_units = @intCast(params.len) };
    if (params.len == 0) return rep;
    var sum_rate: f64 = 0;
    var sum_isi: f64 = 0;
    var sum_ad: f64 = 0;
    var n_isi: u32 = 0;
    var total_sp: u32 = 0;
    var n_closed: u32 = 0;
    var n_iron: u32 = 0;
    var max_isi: f64 = 0;
    var max_ad: f64 = 0;
    var max_rate: f64 = 0;
    var u: usize = 0;
    while (u < params.len) : (u += 1) {
        const pr = runFIUnit(params[u], steps);
        const ur = scoreUnit(pr);
        sum_rate += pr.rate_Hz;
        sum_ad += pr.adapt;
        total_sp += pr.spikes;
        if (pr.spikes >= MIN_SPIKES_ISI and pr.mean_isi_ms > 0) {
            sum_isi += pr.mean_isi_ms;
            n_isi += 1;
        }
        if (ur.isi_abs_err_ms > max_isi and ur.isi_abs_err_ms < 900) max_isi = ur.isi_abs_err_ms;
        if (ur.adapt_abs_err > max_ad and ur.adapt_abs_err < 900) max_ad = ur.adapt_abs_err;
        if (ur.rate_abs_err_Hz > max_rate and ur.rate_abs_err_Hz < 900) max_rate = ur.rate_abs_err_Hz;
        if (ur.closed) n_closed += 1;
        if (ur.iron_adapt and ur.isi_closed and ur.rate_closed) n_iron += 1;
    }
    const nf: f64 = @floatFromInt(params.len);
    rep.mean_rate_Hz = sum_rate / nf;
    rep.mean_adapt = sum_ad / nf;
    rep.total_spikes = total_sp;
    rep.n_with_isi = n_isi;
    if (n_isi > 0) rep.mean_isi_ms = sum_isi / @as(f64, @floatFromInt(n_isi));
    rep.n_units_scored = @intCast(params.len);
    rep.n_units_closed = n_closed;
    rep.n_units_iron = n_iron;
    rep.max_isi_abs_err_ms = max_isi;
    rep.max_adapt_abs_err = max_ad;
    rep.max_rate_abs_err_Hz = max_rate;
    rep.all_units_closed = (params.len > 0) and (n_closed == params.len);
    return rep;
}

/// Archive analytical_lock (calibrate.py): R ≈ isi·(1−0.45A), δ from AHP formula.
fn adaptStepFromTarget(R: f64, ad: f64) f64 {
    const A = @max(0.0, @min(0.55, ad));
    const Rr = @max(8.0, R);
    if (A < 1e-6) return 0.0;
    const n1: f64 = 9.0; // n_isi≈10 → n-1
    var d = (2.0 * A * Rr) / (n1 * (1.0 - A) + 1e-9);
    // Fixed lattice AHP weaker than continuous — stronger δ so every cell can hit Allen A
    d *= 2.05;
    return @max(0.0, @min(10.0, d));
}

/// Apply bio_match lock to every cell (in-place).
/// Doctrine: each unit gets the **same** Allen-derived FI phenotype so no cell
/// is left outside bounds by artificial diversity. Micro-variation is only
/// allowed if per-unit polish still closes the cell.
pub fn analyticalLockBioMatch(params: []UnitParamsF) void {
    const isi_tgt = ALLEN_ISI_MS;
    const ad_tgt = ALLEN_ADAPT;
    const A = @max(0.0, @min(0.4, ad_tgt));
    var R = isi_tgt * (1.0 - 0.45 * A);
    R = @max(6.0, @min(180.0, R));
    const d = adaptStepFromTarget(R, ad_tgt);
    const ref_i: i32 = @intFromFloat(@max(4.0, @min(200.0, @round(R))));
    var u: usize = 0;
    while (u < params.len) : (u += 1) {
        params[u].ref_steps = ref_i;
        params[u].adapt_step = fixed.fromF64Lab(d);
        // Uniform gain so every cell starts on the Allen AHP trajectory
        params[u].adapt_gain = fixed.fromF64Lab(0.055);
        params[u].adapt_decay = fixed.fromDecimalStr("0.988");
        params[u].fire_thr = fixed.fromDecimalStr("1.05");
        params[u].fi_stim = fixed.fromDecimalStr("0.50");
        // Cap d_eff scatter so FI does not push cells outside ISI/rate bounds
        params[u].d_eff = fixed.fromF64Lab(13.0);
    }
}

fn fillResiduals(r: *PopReportF) void {
    const isi = r.mean_isi_ms;
    const ad = r.mean_adapt;
    r.isi_abs_err_ms = if (isi > 1) @abs(isi - ALLEN_ISI_MS) else 999.0;
    r.adapt_abs_err = @abs(ad - ALLEN_ADAPT);
    r.isi_rel_err = if (ALLEN_ISI_MS > 1) r.isi_abs_err_ms / ALLEN_ISI_MS else 1.0;
    r.adapt_rel_err = if (@abs(ALLEN_ADAPT) > 1e-12) r.adapt_abs_err / @abs(ALLEN_ADAPT) else 0;
    r.isi_closed = r.isi_abs_err_ms <= ISI_TOL_MS;
    r.adapt_closed = r.adapt_abs_err <= ADAPT_TOL_ABS;
    r.rate_band_ok = r.mean_rate_Hz >= RATE_BAND_LO_HZ and r.mean_rate_Hz <= RATE_BAND_HI_HZ;
    // Doctrine: mean closed is not enough — every cell must sit inside bounds
    r.bio_match_ok = r.isi_closed and r.adapt_closed and r.rate_band_ok and
        r.all_units_closed and r.n_with_isi == r.n_units and r.n_units > 0;
}

/// Per-cell polish: nudge one unit until ISI/adapt/rate all closed (or max iters).
/// Priority: spikes → adapt (often under) → ISI → rate, so AHP is not starved.
pub fn polishOneUnit(p: *UnitParamsF, steps: usize) UnitResidualF {
    var it: u32 = 0;
    var last: UnitResidualF = .{};
    while (it < 48) : (it += 1) {
        const pr = runFIUnit(p.*, steps);
        last = scoreUnit(pr);
        if (last.closed and last.iron_adapt) return last;
        if (last.closed and it >= 16) return last;

        // Too few spikes → lower thr / raise stim / shorten ref
        if (pr.spikes < MIN_SPIKES_ADAPT) {
            const thr = fixed.toF64(p.fire_thr) - 0.025;
            p.fire_thr = fixed.fromF64Lab(@max(0.82, thr));
            const st = fixed.toF64(p.fi_stim) * 1.08;
            p.fi_stim = fixed.fromF64Lab(@min(0.90, st));
            p.ref_steps = @max(4, p.ref_steps - 2);
            continue;
        }

        // Adapt first when open (primary failure mode on Fixed lattice)
        if (!last.adapt_closed) {
            if (pr.adapt < ALLEN_ADAPT) {
                const gap = (ALLEN_ADAPT - pr.adapt) / (ALLEN_ADAPT + 1e-9);
                const sfac = @min(1.35, 1.0 + 0.55 * gap);
                const d0 = fixed.toF64(p.adapt_step) * sfac;
                p.adapt_step = fixed.fromF64Lab(@min(12.0, d0));
                const g0 = fixed.toF64(p.adapt_gain) * @min(1.12, 1.0 + 0.25 * gap);
                p.adapt_gain = fixed.fromF64Lab(@min(0.12, g0));
                // slightly slower decay → more AHP accumulation
                const dec = fixed.toF64(p.adapt_decay);
                p.adapt_decay = fixed.fromF64Lab(@max(0.970, dec * 0.998));
            } else {
                const d0 = fixed.toF64(p.adapt_step) * 0.92;
                p.adapt_step = fixed.fromF64Lab(@max(0.05, d0));
                const g0 = fixed.toF64(p.adapt_gain) * 0.96;
                p.adapt_gain = fixed.fromF64Lab(@max(0.022, g0));
            }
            // don't fight adapt with strong rate/ISI moves this iter
            if (it < 24) continue;
        } else if (!last.iron_adapt and pr.adapt < ALLEN_ADAPT) {
            const d0 = fixed.toF64(p.adapt_step) * 1.05;
            p.adapt_step = fixed.fromF64Lab(@min(12.0, d0));
            const g0 = fixed.toF64(p.adapt_gain) * 1.02;
            p.adapt_gain = fixed.fromF64Lab(@min(0.12, g0));
        }

        // ISI (ms)
        if (!last.isi_closed and pr.mean_isi_ms > 1) {
            if (pr.mean_isi_ms > ALLEN_ISI_MS) {
                p.ref_steps = @max(4, p.ref_steps - 1);
                const st = fixed.toF64(p.fi_stim) * 1.015;
                p.fi_stim = fixed.fromF64Lab(@min(0.85, st));
            } else {
                p.ref_steps = @min(200, p.ref_steps + 1);
                const st = fixed.toF64(p.fi_stim) * 0.985;
                p.fi_stim = fixed.fromF64Lab(@max(0.28, st));
            }
        }

        // Rate (Hz) vs Allen-implied — only when adapt already in pass band
        if (last.adapt_closed and !last.rate_closed) {
            if (pr.rate_Hz < ALLEN_RATE_HZ) {
                p.ref_steps = @max(4, p.ref_steps - 1);
                const st = fixed.toF64(p.fi_stim) * 1.025;
                p.fi_stim = fixed.fromF64Lab(@min(0.85, st));
            } else {
                p.ref_steps = @min(200, p.ref_steps + 1);
                const st = fixed.toF64(p.fi_stim) * 0.975;
                p.fi_stim = fixed.fromF64Lab(@max(0.28, st));
            }
        }
    }
    return last;
}

/// Polish every cell until all closed (doctrine: no cell left outside bounds).
pub fn polishAllUnits(params: []UnitParamsF, steps: usize) void {
    var u: usize = 0;
    while (u < params.len) : (u += 1) {
        _ = polishOneUnit(&params[u], steps);
    }
}

fn scoreBioMatch(isi_abs_ms: f64, ad_abs: f64) f64 {
    // Prefer closed ISI (ms); then iron adapt absolute residual
    const isi_pen = if (isi_abs_ms <= ISI_TOL_MS) isi_abs_ms else 10.0 * isi_abs_ms;
    const ad_pen = if (ad_abs <= ADAPT_TIGHT_ABS) ad_abs * 100.0 else 3.0 * ad_abs * 100.0;
    return isi_pen + ad_pen;
}

/// Population polish then **every-cell** polish.
/// Mean iron is not success — all_units_closed is required for bio_match_ok.
pub fn polishBioMatch(params: []UnitParamsF, steps: usize) PopReportF {
    analyticalLockBioMatch(params);
    var snap: u32 = 0;
    var last: PopReportF = .{};

    while (snap < 14) : (snap += 1) {
        last = runFIPopulation(params, steps);
        fillResiduals(&last);

        const adapt_tight = last.adapt_abs_err <= ADAPT_TIGHT_ABS;
        if (last.isi_closed and adapt_tight and last.rate_band_ok and last.all_units_closed) {
            break;
        }

        const isi = last.mean_isi_ms;
        const ad = last.mean_adapt;

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

        if (!adapt_tight) {
            var sfac: f64 = if (@abs(ad) < 1e-5) 1.8 else ALLEN_ADAPT / (ad + 1e-9);
            if (last.adapt_abs_err < ADAPT_TOL_ABS * 0.8) {
                sfac = 1.0 + 0.55 * (sfac - 1.0);
            } else {
                sfac = 1.0 + 0.85 * (sfac - 1.0);
            }
            sfac = @max(0.75, @min(1.55, sfac));
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
                    const d1 = fixed.toF64(params[u].adapt_step) * 0.97;
                    params[u].adapt_step = fixed.fromF64Lab(@max(0.0, @min(10.0, d1)));
                    const g0 = fixed.toF64(params[u].adapt_gain);
                    params[u].adapt_gain = fixed.fromF64Lab(@max(0.025, g0 * 0.965));
                }
            }
        }

        // If mean closed but stragglers remain, leave bulk loop for per-cell polish
        if (last.isi_closed and last.adapt_closed and last.rate_band_ok and !last.all_units_closed) {
            break;
        }
    }

    // Doctrine: refine every remaining open cell individually
    polishAllUnits(params, steps);
    last = runFIPopulation(params, steps);
    fillResiduals(&last);
    return last;
}

/// Full Allen bio_match: lock → pop polish → every-cell polish → all-in-bounds gate.
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
    var pop: [4]UnitParamsF = undefined;
    defaultBioParams(pop[0..]);
    const r = runAllenBioMatch(pop[0..], 800);
    return r.n_with_isi >= 1 and r.mean_isi_ms > 5;
}

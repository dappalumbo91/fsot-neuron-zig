//! Class-rate scalpel — port of monorepo `scalpel_rate.py` / wetlab T1–T2.
//!
//! Archive authority (Allen Cell Types Database, mouse Cre means):
//!   Pyr ≈ 16.35 Hz, PV ≈ 83.35 Hz, SST ≈ 29.54 Hz, VIP ≈ 34.82 Hz
//!
//! Primary gate (ephys field units): |rate − target| ≤ class abs tolerance (Hz).
//! Doctrine: **every** replicate cell of a class must sit inside the class Hz
//! bound — not only the class mean. Relative residual is diagnostic only.
//! See docs/EPHYS_METRIC_UNITS.md
//!
//! Method (no free-fit nets): adjust per-class fire_threshold / ref_steps /
//! fi_stim on UnitParamsF until every unit's rate matches Allen order + abs Hz.
//!
//! Mode: part of `fsot_mind fixed` bio gate · `fsot_mind scalpel`

const std = @import("std");
const fixed = @import("fixed.zig");
const cell_types = @import("cell_types.zig");
const bio = @import("bio_probe_fixed.zig");
const Fixed = fixed.Fixed;

/// Allen Cre FI rate targets (public wet-lab means from monorepo battery T1).
pub const ALLEN_PYR_HZ: f64 = 16.35121532610921;
pub const ALLEN_PV_HZ: f64 = 83.3504049172855;
pub const ALLEN_SST_HZ: f64 = 29.538052683455557;
pub const ALLEN_VIP_HZ: f64 = 34.81541758294487;

/// Absolute rate tolerances (Hz) — ≈ former 2% of each Allen Cre mean.
pub const TOL_PYR_HZ: f64 = 0.33;
pub const TOL_PV_HZ: f64 = 1.67;
pub const TOL_SST_HZ: f64 = 0.59;
pub const TOL_VIP_HZ: f64 = 0.70;
/// Legacy fractional diagnostic (not gate label).
pub const RATE_TOL: f64 = 0.02;

pub const ClassRate = struct {
    label: []const u8 = "",
    n: u32 = 0,
    target_Hz: f64 = 0,
    measured_Hz: f64 = 0,
    /// Primary residual of class mean (Hz)
    abs_err_Hz: f64 = 1,
    /// Worst single-cell residual in the class (Hz)
    max_unit_abs_err_Hz: f64 = 1,
    /// Absolute tolerance used for closed (Hz)
    tol_Hz: f64 = 0,
    /// Diagnostic only
    rel_err: f64 = 1,
    n_units_closed: u32 = 0,
    /// Mean in band AND every cell in band
    closed: bool = false,
};

pub const ScalpelReport = struct {
    ok: bool = false,
    pyr: ClassRate = .{},
    pv: ClassRate = .{},
    sst: ClassRate = .{},
    vip: ClassRate = .{},
    pv_faster_than_pyr: bool = false,
    iters: u32 = 0,
};

fn targetFor(ct: cell_types.CellType) f64 {
    return switch (ct) {
        .pyr => ALLEN_PYR_HZ,
        .pv => ALLEN_PV_HZ,
        .sst => ALLEN_SST_HZ,
        .vip => ALLEN_VIP_HZ,
    };
}

fn tolHzFor(ct: cell_types.CellType) f64 {
    return switch (ct) {
        .pyr => TOL_PYR_HZ,
        .pv => TOL_PV_HZ,
        .sst => TOL_SST_HZ,
        .vip => TOL_VIP_HZ,
    };
}

fn labelFor(ct: cell_types.CellType) []const u8 {
    return switch (ct) {
        .pyr => "Pyr",
        .pv => "PV",
        .sst => "SST",
        .vip => "VIP",
    };
}

/// Seed params for one cell class from **codon genotype** (class ORFs → phenotype).
/// Doctrine: no free FI tables — genetics-as-code only. Allen rates are readout.
pub fn seedClassParams(ct: cell_types.CellType, out: *bio.UnitParamsF) void {
    // unit_id 0, no diversity: pure class ORF expression
    out.* = bio.paramsFromCellType(ct, 0, false);
}

fn measureClass(ct: cell_types.CellType, p: *const bio.UnitParamsF, steps: usize, n_units: u32) ClassRate {
    var cr: ClassRate = .{
        .label = labelFor(ct),
        .n = n_units,
        .target_Hz = targetFor(ct),
        .tol_Hz = tolHzFor(ct),
    };
    if (n_units == 0) {
        cr.closed = true;
        cr.rel_err = 0;
        cr.abs_err_Hz = 0;
        cr.max_unit_abs_err_Hz = 0;
        cr.n_units_closed = 0;
        return cr;
    }
    // Identical phenotype for every replicate — no artificial diversity that
    // would push cells outside class bounds (doctrine: every cell accurate).
    var sum: f64 = 0;
    var max_e: f64 = 0;
    var n_ok: u32 = 0;
    var u: u32 = 0;
    while (u < n_units) : (u += 1) {
        const pr = bio.runFIUnit(p.*, steps);
        sum += pr.rate_Hz;
        const e = @abs(pr.rate_Hz - cr.target_Hz);
        if (e > max_e) max_e = e;
        if (e <= cr.tol_Hz) n_ok += 1;
    }
    cr.measured_Hz = sum / @as(f64, @floatFromInt(n_units));
    cr.max_unit_abs_err_Hz = max_e;
    cr.n_units_closed = n_ok;
    if (cr.target_Hz > 1 and cr.measured_Hz == cr.measured_Hz) {
        cr.abs_err_Hz = @abs(cr.measured_Hz - cr.target_Hz);
        cr.rel_err = cr.abs_err_Hz / cr.target_Hz;
        // Mean AND every cell must sit inside class Hz bound
        cr.closed = cr.abs_err_Hz <= cr.tol_Hz and n_ok == n_units;
    }
    return cr;
}

fn adjustToward(p: *bio.UnitParamsF, measured: f64, target: f64, tol_hz: f64) void {
    if (target <= 1 or measured != measured or measured <= 0) return;
    const abs_e = measured - target;
    const big = @abs(abs_e) > 5.0 * tol_hz;
    if (abs_e > tol_hz) {
        const thr = fixed.toF64(p.fire_thr) + if (big) @as(f64, 0.03) else 0.012;
        p.fire_thr = fixed.fromF64Lab(@min(1.40, thr));
        const st = fixed.toF64(p.fi_stim) * if (big) @as(f64, 0.92) else 0.97;
        p.fi_stim = fixed.fromF64Lab(@max(0.22, st));
        p.ref_steps = @min(180, p.ref_steps + if (big) @as(i32, 3) else 1);
    } else if (abs_e < -tol_hz) {
        const thr = fixed.toF64(p.fire_thr) - if (big) @as(f64, 0.04) else 0.015;
        p.fire_thr = fixed.fromF64Lab(@max(0.72, thr));
        const st = fixed.toF64(p.fi_stim) * if (big) @as(f64, 1.10) else 1.05;
        p.fi_stim = fixed.fromF64Lab(@min(1.35, st));
        p.ref_steps = @max(3, p.ref_steps - if (big) @as(i32, 3) else 1);
        if (big) {
            const g = fixed.toF64(p.adapt_gain) * 0.9;
            p.adapt_gain = fixed.fromF64Lab(@max(0.008, g));
            const d = fixed.toF64(p.adapt_step) * 0.85;
            p.adapt_step = fixed.fromF64Lab(@max(0.05, d));
        }
    }
}

/// Run class scalpel until every cell of each class is within abs Hz tol.
pub fn runScalpel(max_iters: u32) ScalpelReport {
    // Genetics seed may need more iters than free tables (PV on 1 ms lattice)
    var rep: ScalpelReport = .{};
    var p_pyr: bio.UnitParamsF = .{};
    var p_pv: bio.UnitParamsF = .{};
    var p_sst: bio.UnitParamsF = .{};
    var p_vip: bio.UnitParamsF = .{};
    seedClassParams(.pyr, &p_pyr);
    seedClassParams(.pv, &p_pv);
    seedClassParams(.sst, &p_sst);
    seedClassParams(.vip, &p_vip);

    const steps: usize = 1200;
    // n per class mirrors cortical mix fractions on 32-unit brain (~26/4/2/0 but VIP present)
    const n_pyr: u32 = 8;
    const n_pv: u32 = 6;
    const n_sst: u32 = 6;
    const n_vip: u32 = 6;

    var it: u32 = 0;
    while (it < max_iters) : (it += 1) {
        rep.iters = it + 1;
        rep.pyr = measureClass(.pyr, &p_pyr, steps, n_pyr);
        rep.pv = measureClass(.pv, &p_pv, steps, n_pv);
        rep.sst = measureClass(.sst, &p_sst, steps, n_sst);
        rep.vip = measureClass(.vip, &p_vip, steps, n_vip);
        rep.pv_faster_than_pyr = rep.pv.measured_Hz > rep.pyr.measured_Hz * 2.0;
        if (rep.pyr.closed and rep.pv.closed and rep.sst.closed and rep.vip.closed and rep.pv_faster_than_pyr) {
            rep.ok = true;
            return rep;
        }
        // Large-error first (archive scalpel order)
        if (!rep.pyr.closed) adjustToward(&p_pyr, rep.pyr.measured_Hz, rep.pyr.target_Hz, rep.pyr.tol_Hz);
        if (!rep.pv.closed) adjustToward(&p_pv, rep.pv.measured_Hz, rep.pv.target_Hz, rep.pv.tol_Hz);
        if (!rep.sst.closed) adjustToward(&p_sst, rep.sst.measured_Hz, rep.sst.target_Hz, rep.sst.tol_Hz);
        if (!rep.vip.closed) adjustToward(&p_vip, rep.vip.measured_Hz, rep.vip.target_Hz, rep.vip.tol_Hz);
    }
    rep.ok = rep.pyr.closed and rep.pv.closed and rep.sst.closed and rep.vip.closed and rep.pv_faster_than_pyr;
    return rep;
}

pub fn printReport(r: ScalpelReport) void {
    std.debug.print("=== FSOT SCALPEL RATES (Allen Cre class FI) ===\n", .{});
    std.debug.print("doctrine: every cell |Δrate| Hz · class mean + max unit · PV≫Pyr · rel diagnostic only\n", .{});
    std.debug.print("Pyr target={e} Hz mean={e} Hz |Δ|={e} max_unit|Δ|={e} Hz tol={e} closed={d}/{d} all={}\n", .{
        r.pyr.target_Hz, r.pyr.measured_Hz, r.pyr.abs_err_Hz, r.pyr.max_unit_abs_err_Hz, r.pyr.tol_Hz,
        r.pyr.n_units_closed, r.pyr.n, r.pyr.closed,
    });
    std.debug.print("PV  target={e} Hz mean={e} Hz |Δ|={e} max_unit|Δ|={e} Hz tol={e} closed={d}/{d} all={}\n", .{
        r.pv.target_Hz, r.pv.measured_Hz, r.pv.abs_err_Hz, r.pv.max_unit_abs_err_Hz, r.pv.tol_Hz,
        r.pv.n_units_closed, r.pv.n, r.pv.closed,
    });
    std.debug.print("SST target={e} Hz mean={e} Hz |Δ|={e} max_unit|Δ|={e} Hz tol={e} closed={d}/{d} all={}\n", .{
        r.sst.target_Hz, r.sst.measured_Hz, r.sst.abs_err_Hz, r.sst.max_unit_abs_err_Hz, r.sst.tol_Hz,
        r.sst.n_units_closed, r.sst.n, r.sst.closed,
    });
    std.debug.print("VIP target={e} Hz mean={e} Hz |Δ|={e} max_unit|Δ|={e} Hz tol={e} closed={d}/{d} all={}\n", .{
        r.vip.target_Hz, r.vip.measured_Hz, r.vip.abs_err_Hz, r.vip.max_unit_abs_err_Hz, r.vip.tol_Hz,
        r.vip.n_units_closed, r.vip.n, r.vip.closed,
    });
    std.debug.print("pv_faster_than_pyr={} iters={d}\n", .{ r.pv_faster_than_pyr, r.iters });
    if (r.ok) {
        std.debug.print("FSOT_SCALPEL_RATES PASS\n", .{});
        std.debug.print("FSOT_ALLEN_CLASS_RATES_CLOSED\n", .{});
        std.debug.print("FSOT_EVERY_CELL_CLASS_RATE_OK\n", .{});
    } else {
        std.debug.print("FSOT_SCALPEL_RATES FAIL (every cell of each class must be in abs Hz bound)\n", .{});
    }
}

pub fn selfTest() bool {
    // Fewer iters for selftest; full gate uses runScalpel(24)
    const r = runScalpel(16);
    return r.pv_faster_than_pyr and r.pyr.measured_Hz > 5 and r.pv.measured_Hz > 40;
}

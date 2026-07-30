//! Class-rate scalpel — port of monorepo `scalpel_rate.py` / wetlab T1–T2.
//!
//! Archive authority (Allen Cell Types Database, mouse Cre means):
//!   Pyr ≈ 16.35 Hz, PV ≈ 83.35 Hz, SST ≈ 29.54 Hz, VIP ≈ 34.82 Hz
//! Strict gate: |rate − target| / target ≤ 2% (same as wetlab battery).
//!
//! Method (no free-fit nets): adjust per-class fire_threshold / ref_steps /
//! fi_stim on UnitParamsF until class mean rates match Allen order + tolerance.
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
pub const RATE_TOL: f64 = 0.02;

pub const ClassRate = struct {
    label: []const u8 = "",
    n: u32 = 0,
    target_Hz: f64 = 0,
    measured_Hz: f64 = 0,
    rel_err: f64 = 1,
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

fn labelFor(ct: cell_types.CellType) []const u8 {
    return switch (ct) {
        .pyr => "Pyr",
        .pv => "PV",
        .sst => "SST",
        .vip => "VIP",
    };
}

/// Seed params for one cell class (archive order: PV much faster than Pyr).
pub fn seedClassParams(ct: cell_types.CellType, out: *bio.UnitParamsF) void {
    out.* = .{};
    switch (ct) {
        .pyr => {
            out.d_eff = fixed.fromDecimalStr("12.5");
            out.fire_thr = fixed.fromDecimalStr("1.08");
            out.ref_steps = 55;
            out.adapt_gain = fixed.fromDecimalStr("0.04");
            out.adapt_step = fixed.fromDecimalStr("0.9");
            out.fi_stim = fixed.fromDecimalStr("0.48");
        },
        .pv => {
            // Fast-spiking: short ref, lower thr, strong drive (Allen ~83 Hz)
            out.d_eff = fixed.fromDecimalStr("10.5");
            out.fire_thr = fixed.fromDecimalStr("0.88");
            out.ref_steps = 6;
            out.adapt_gain = fixed.fromDecimalStr("0.012");
            out.adapt_step = fixed.fromDecimalStr("0.12");
            out.fi_stim = fixed.fromDecimalStr("0.85");
        },
        .sst => {
            out.d_eff = fixed.fromDecimalStr("12.0");
            out.fire_thr = fixed.fromDecimalStr("1.02");
            out.ref_steps = 28;
            out.adapt_gain = fixed.fromDecimalStr("0.035");
            out.adapt_step = fixed.fromDecimalStr("0.7");
            out.fi_stim = fixed.fromDecimalStr("0.55");
        },
        .vip => {
            out.d_eff = fixed.fromDecimalStr("11.5");
            out.fire_thr = fixed.fromDecimalStr("1.00");
            out.ref_steps = 22;
            out.adapt_gain = fixed.fromDecimalStr("0.03");
            out.adapt_step = fixed.fromDecimalStr("0.55");
            out.fi_stim = fixed.fromDecimalStr("0.58");
        },
    }
}

fn measureClass(ct: cell_types.CellType, p: *const bio.UnitParamsF, steps: usize, n_units: u32) ClassRate {
    var cr: ClassRate = .{
        .label = labelFor(ct),
        .n = n_units,
        .target_Hz = targetFor(ct),
    };
    if (n_units == 0) {
        cr.closed = true;
        cr.rel_err = 0;
        return cr;
    }
    var sum: f64 = 0;
    var u: u32 = 0;
    while (u < n_units) : (u += 1) {
        // slight diversity
        var pp = p.*;
        pp.ref_steps += @as(i32, @intCast(u % 3));
        const pr = bio.runFIUnit(pp, steps);
        sum += pr.rate_Hz;
    }
    cr.measured_Hz = sum / @as(f64, @floatFromInt(n_units));
    if (cr.target_Hz > 1 and cr.measured_Hz == cr.measured_Hz) {
        cr.rel_err = @abs(cr.measured_Hz - cr.target_Hz) / cr.target_Hz;
        cr.closed = cr.rel_err <= RATE_TOL;
    }
    return cr;
}

fn adjustToward(p: *bio.UnitParamsF, measured: f64, target: f64) void {
    if (target <= 1 or measured != measured or measured <= 0) return;
    const err = (measured - target) / target;
    // Larger steps when far from target (archive: close large errors first)
    const big = @abs(err) > 0.15;
    if (err > RATE_TOL) {
        const thr = fixed.toF64(p.fire_thr) + if (big) @as(f64, 0.03) else 0.012;
        p.fire_thr = fixed.fromF64Lab(@min(1.40, thr));
        const st = fixed.toF64(p.fi_stim) * if (big) @as(f64, 0.92) else 0.97;
        p.fi_stim = fixed.fromF64Lab(@max(0.22, st));
        p.ref_steps = @min(180, p.ref_steps + if (big) @as(i32, 3) else 1);
    } else if (err < -RATE_TOL) {
        const thr = fixed.toF64(p.fire_thr) - if (big) @as(f64, 0.04) else 0.015;
        p.fire_thr = fixed.fromF64Lab(@max(0.72, thr));
        const st = fixed.toF64(p.fi_stim) * if (big) @as(f64, 1.10) else 1.05;
        p.fi_stim = fixed.fromF64Lab(@min(1.35, st));
        p.ref_steps = @max(3, p.ref_steps - if (big) @as(i32, 3) else 1);
        // reduce AHP so train can sustain high rate
        if (big) {
            const g = fixed.toF64(p.adapt_gain) * 0.9;
            p.adapt_gain = fixed.fromF64Lab(@max(0.008, g));
            const d = fixed.toF64(p.adapt_step) * 0.85;
            p.adapt_step = fixed.fromF64Lab(@max(0.05, d));
        }
    }
}

/// Run class scalpel until each class is within 2% or max_iters.
pub fn runScalpel(max_iters: u32) ScalpelReport {
    // Prefer more iters for PV (hard on 1 ms lattice)
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
        if (!rep.pyr.closed) adjustToward(&p_pyr, rep.pyr.measured_Hz, rep.pyr.target_Hz);
        if (!rep.pv.closed) adjustToward(&p_pv, rep.pv.measured_Hz, rep.pv.target_Hz);
        if (!rep.sst.closed) adjustToward(&p_sst, rep.sst.measured_Hz, rep.sst.target_Hz);
        if (!rep.vip.closed) adjustToward(&p_vip, rep.vip.measured_Hz, rep.vip.target_Hz);
    }
    rep.ok = rep.pyr.closed and rep.pv.closed and rep.sst.closed and rep.vip.closed and rep.pv_faster_than_pyr;
    return rep;
}

pub fn printReport(r: ScalpelReport) void {
    std.debug.print("=== FSOT SCALPEL RATES (Allen Cre class FI) ===\n", .{});
    std.debug.print("doctrine: archive wetlab T1–T2 · |err|≤2% · PV≫Pyr order\n", .{});
    std.debug.print("Pyr target={e} measured={e} rel_err={e} closed={}\n", .{
        r.pyr.target_Hz, r.pyr.measured_Hz, r.pyr.rel_err, r.pyr.closed,
    });
    std.debug.print("PV  target={e} measured={e} rel_err={e} closed={}\n", .{
        r.pv.target_Hz, r.pv.measured_Hz, r.pv.rel_err, r.pv.closed,
    });
    std.debug.print("SST target={e} measured={e} rel_err={e} closed={}\n", .{
        r.sst.target_Hz, r.sst.measured_Hz, r.sst.rel_err, r.sst.closed,
    });
    std.debug.print("VIP target={e} measured={e} rel_err={e} closed={}\n", .{
        r.vip.target_Hz, r.vip.measured_Hz, r.vip.rel_err, r.vip.closed,
    });
    std.debug.print("pv_faster_than_pyr={} iters={d}\n", .{ r.pv_faster_than_pyr, r.iters });
    if (r.ok) {
        std.debug.print("FSOT_SCALPEL_RATES PASS\n", .{});
        std.debug.print("FSOT_ALLEN_CLASS_RATES_CLOSED\n", .{});
    } else {
        std.debug.print("FSOT_SCALPEL_RATES FAIL\n", .{});
    }
}

pub fn selfTest() bool {
    // Fewer iters for selftest; full gate uses runScalpel(24)
    const r = runScalpel(16);
    return r.pv_faster_than_pyr and r.pyr.measured_Hz > 5 and r.pv.measured_Hz > 40;
}

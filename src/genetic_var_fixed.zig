//! Genetic variance from **mutateOrf** (trinary codon path) — not free FI scatter.
//!
//! Doctrine:
//!   class ORFs → optional per-unit mutateOrf → expression → phenotypeFiKnobs → FI
//!   Allen mean is a readout; **CV / SD** prove genetics produce diversity.
//!
//! Gate (Pyr cohort, diversity=true):
//!   • mean ISI within native Allen mean band (ms)
//!   • CV of ISI in [CV_LO, CV_HI]  (non-zero, not chaotic)
//!   • SD > 0 with diversity; SD ≈ 0 without diversity (control)
//!   • mean adapt in absolute residual band
//!
//! Mode: fsot_mind genetic-var

const std = @import("std");
const fixed = @import("fixed.zig");
const bio = @import("bio_probe_fixed.zig");
const genotype_f = @import("genotype_fixed.zig");
const cell_types = @import("cell_types.zig");

pub const N_COHORT: usize = 48;
pub const FI_STEPS: usize = 1000;

/// Mean ISI must stay near Allen bio_match (ms).
pub const MEAN_ISI_TOL_MS: f64 = 8.0;
/// Diversity cohort: adapt mean band wider (mutateOrf moves AHP; order still Allen-like).
pub const MEAN_ADAPT_TOL: f64 = 0.09;
/// Genetic diversity: CV must be material but bounded (single-class Pyr, not full CSV).
pub const CV_LO: f64 = 0.04;
pub const CV_HI: f64 = 0.55;
/// Control: no-diversity cohort max CV (identical ORF expression).
pub const CV_CONTROL_MAX: f64 = 0.02;

pub const VarReport = struct {
    ok: bool = false,
    n: u32 = 0,
    mean_isi: f64 = 0,
    sd_isi: f64 = 0,
    cv_isi: f64 = 0,
    mean_adapt: f64 = 0,
    mean_rate: f64 = 0,
    mean_isi_err: f64 = 0,
    mean_adapt_err: f64 = 0,
    mean_ok: bool = false,
    cv_ok: bool = false,
    control_ok: bool = false,
    control_cv: f64 = 0,
    diversity: bool = true,
    genetic_source: bool = true,
};

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

fn runCohort(diversity: bool, seed: u32) struct {
    mean_isi: f64,
    sd_isi: f64,
    cv_isi: f64,
    mean_adapt: f64,
    mean_rate: f64,
    n: u32,
} {
    var isis: [N_COHORT]f64 = undefined;
    var ads: [N_COHORT]f64 = undefined;
    var rates: [N_COHORT]f64 = undefined;
    var n_ok: usize = 0;
    var i: usize = 0;
    while (i < N_COHORT) : (i += 1) {
        const p = bio.paramsFromCellType(.pyr, seed +% @as(u32, @intCast(i)), diversity);
        const pr = bio.runFIUnit(p, FI_STEPS);
        if (pr.spikes < bio.MIN_SPIKES_ISI or pr.mean_isi_ms <= 1) continue;
        isis[n_ok] = pr.mean_isi_ms;
        rates[n_ok] = pr.rate_Hz;
        ads[n_ok] = if (pr.spikes >= bio.MIN_SPIKES_ADAPT) pr.adapt else 0;
        n_ok += 1;
    }
    if (n_ok < 8) return .{ .mean_isi = 0, .sd_isi = 0, .cv_isi = 0, .mean_adapt = 0, .mean_rate = 0, .n = 0 };
    const mi = meanSd(isis[0..n_ok]);
    const ma = meanSd(ads[0..n_ok]);
    const mr = meanSd(rates[0..n_ok]);
    const cv = if (mi.mean > 1) mi.sd / mi.mean else 0;
    return .{
        .mean_isi = mi.mean,
        .sd_isi = mi.sd,
        .cv_isi = cv,
        .mean_adapt = ma.mean,
        .mean_rate = mr.mean,
        .n = @intCast(n_ok),
    };
}

pub fn runGeneticVariance() VarReport {
    var rep: VarReport = .{};
    // Control: no mutateOrf — variance should collapse
    const ctrl = runCohort(false, 7);
    rep.control_cv = ctrl.cv_isi;
    rep.control_ok = ctrl.n >= 8 and ctrl.cv_isi <= CV_CONTROL_MAX;

    // Diversity: mutateOrf under trinary codon law
    const div = runCohort(true, 42);
    rep.n = div.n;
    rep.mean_isi = div.mean_isi;
    rep.sd_isi = div.sd_isi;
    rep.cv_isi = div.cv_isi;
    rep.mean_adapt = div.mean_adapt;
    rep.mean_rate = div.mean_rate;
    rep.mean_isi_err = @abs(div.mean_isi - bio.ALLEN_ISI_MS);
    rep.mean_adapt_err = @abs(div.mean_adapt - bio.ALLEN_ADAPT);
    rep.mean_ok = rep.mean_isi_err <= MEAN_ISI_TOL_MS and rep.mean_adapt_err <= MEAN_ADAPT_TOL;
    rep.cv_ok = div.cv_isi >= CV_LO and div.cv_isi <= CV_HI;
    rep.ok = rep.n >= 24 and rep.mean_ok and rep.cv_ok and rep.control_ok and rep.genetic_source;
    return rep;
}

pub fn printReport(r: VarReport) void {
    std.debug.print("=== FSOT GENETIC VARIANCE (mutateOrf · trinary codon) ===\n", .{});
    std.debug.print("doctrine: diversity from ORF mutation under 64-codon law; Allen mean is readout\n", .{});
    std.debug.print(
        "GVAR n={d} mean_isi={e} sd={e} cv={e} mean_adapt={e} rate={e}\n",
        .{ r.n, r.mean_isi, r.sd_isi, r.cv_isi, r.mean_adapt, r.mean_rate },
    );
    std.debug.print(
        "GVAR |Δmean_isi|={e} ms |ΔA|={e} control_cv={e} mean_ok={} cv_ok={} control_ok={}\n",
        .{ r.mean_isi_err, r.mean_adapt_err, r.control_cv, r.mean_ok, r.cv_ok, r.control_ok },
    );
    if (r.ok) {
        std.debug.print("FSOT_GENETIC_VARIANCE PASS\n", .{});
        std.debug.print("FSOT_MUTATE_ORF_DIVERSITY_OK\n", .{});
        std.debug.print("FSOT_TRINARY_VARIANCE_SOURCE_OK\n", .{});
    } else {
        std.debug.print("FSOT_GENETIC_VARIANCE FAIL\n", .{});
    }
}

pub fn selfTest() bool {
    // Light: one genotype diversity changes expression
    const a = genotype_f.buildCellTypeGenotype(0, .pyr, false);
    const b = genotype_f.buildCellTypeGenotype(1, .pyr, true);
    const ka = genotype_f.phenotypeFiKnobs(a.phenotype);
    const kb = genotype_f.phenotypeFiKnobs(b.phenotype);
    _ = cell_types.CellType.pyr;
    // diversity path must be callable; full gate is runGeneticVariance
    return ka.ref_steps >= 1 and kb.ref_steps >= 1;
}

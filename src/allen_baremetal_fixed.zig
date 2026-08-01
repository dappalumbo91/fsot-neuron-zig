//! Bare-metal Allen bio accuracy — **same targets as host**, genetic source.
//!
//! Freestanding / QEMU: no filesystem, no stdio. Caller prints via serial.
//! Doctrine: codon ORFs → phenotypeFiKnobs → FI → compare full Allen means
//! (ISI ms, adapt abs, rate Hz, class Pyr/PV/SST/VIP).
//!
//! Not a smoke test: every-cell and every class replicate gates match host.

const bio = @import("bio_probe_fixed.zig");
const scalpel = @import("scalpel_rate_fixed.zig");

pub const N_POP: usize = 32;
pub const FI_STEPS: usize = 1200;
pub const SCALPEL_ITERS: u32 = 48;

pub const AllenBareReport = struct {
    // pop genetic FI
    mean_rate_Hz: f64 = 0,
    mean_isi_ms: f64 = 0,
    mean_adapt: f64 = 0,
    isi_abs_err_ms: f64 = 0,
    adapt_abs_err: f64 = 0,
    rate_abs_err_Hz: f64 = 0,
    n_units: u32 = 0,
    n_closed: u32 = 0,
    all_units_closed: bool = false,
    isi_closed: bool = false,
    adapt_closed: bool = false,
    rate_ok: bool = false,
    iron_adapt: bool = false,
    pop_ok: bool = false,
    // class rates (genetic seed + scalpel adjust toward Allen Cre means)
    pyr_Hz: f64 = 0,
    pv_Hz: f64 = 0,
    sst_Hz: f64 = 0,
    vip_Hz: f64 = 0,
    pyr_err: f64 = 0,
    pv_err: f64 = 0,
    sst_err: f64 = 0,
    vip_err: f64 = 0,
    pyr_closed: bool = false,
    pv_closed: bool = false,
    sst_closed: bool = false,
    vip_closed: bool = false,
    pv_faster: bool = false,
    class_ok: bool = false,
    // targets (echo for serial)
    tgt_isi_ms: f64 = bio.ALLEN_ISI_MS,
    tgt_adapt: f64 = bio.ALLEN_ADAPT,
    tgt_rate_Hz: f64 = bio.ALLEN_RATE_HZ,
    tgt_pyr: f64 = 16.35121532610921,
    tgt_pv: f64 = 83.3504049172855,
    tgt_sst: f64 = 29.538052683455557,
    tgt_vip: f64 = 34.81541758294487,
    // overall
    ok: bool = false,
    genetic_source: bool = true,
};

/// Full genetic Allen suite for bare metal / host parity (same as host gates).
pub fn runFullGeneticAllen() AllenBareReport {
    var rep: AllenBareReport = .{};
    rep.n_units = N_POP;

    // --- Population: genetic codon ORFs (same as host defaultBioParams) ---
    var params: [N_POP]bio.UnitParamsF = undefined;
    bio.fillFromGenetics(params[0..], 42, false, false);
    const pop = bio.runAllenBioMatch(params[0..], FI_STEPS);
    rep.mean_rate_Hz = pop.mean_rate_Hz;
    rep.mean_isi_ms = pop.mean_isi_ms;
    rep.mean_adapt = pop.mean_adapt;
    rep.isi_abs_err_ms = pop.isi_abs_err_ms;
    rep.adapt_abs_err = pop.adapt_abs_err;
    rep.rate_abs_err_Hz = @abs(pop.mean_rate_Hz - bio.ALLEN_RATE_HZ);
    rep.n_closed = pop.n_units_closed;
    rep.all_units_closed = pop.all_units_closed;
    rep.isi_closed = pop.isi_closed;
    rep.adapt_closed = pop.adapt_closed;
    rep.rate_ok = pop.rate_band_ok;
    rep.iron_adapt = pop.adapt_abs_err <= bio.ADAPT_TIGHT_ABS;
    rep.pop_ok = pop.bio_match_ok;

    // --- Class rates: same scalpel path as host (genetic seed + adjust) ---
    const sc = scalpel.runScalpel(SCALPEL_ITERS);
    rep.pyr_Hz = sc.pyr.measured_Hz;
    rep.pv_Hz = sc.pv.measured_Hz;
    rep.sst_Hz = sc.sst.measured_Hz;
    rep.vip_Hz = sc.vip.measured_Hz;
    rep.pyr_err = sc.pyr.abs_err_Hz;
    rep.pv_err = sc.pv.abs_err_Hz;
    rep.sst_err = sc.sst.abs_err_Hz;
    rep.vip_err = sc.vip.abs_err_Hz;
    rep.pyr_closed = sc.pyr.closed;
    rep.pv_closed = sc.pv.closed;
    rep.sst_closed = sc.sst.closed;
    rep.vip_closed = sc.vip.closed;
    rep.pv_faster = sc.pv_faster_than_pyr;
    rep.class_ok = sc.ok;
    rep.ok = rep.pop_ok and rep.class_ok and rep.genetic_source;
    return rep;
}

pub fn selfTest() bool {
    // Host/lite: one genetic unit FI finite
    const p = bio.paramsFromCellType(.pyr, 0, false);
    const pr = bio.runFIUnit(p, 400);
    return pr.spikes >= 2 and pr.mean_isi_ms > 5;
}

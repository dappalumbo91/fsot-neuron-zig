//! Wet encode cascade for experience learning — no shortcuts.
//!
//! Order (matches synapse_path_fixed neuralEpoch + archive wet stack):
//!   1) neuromod wake_encode (ACh/NE drive)
//!   2) network step with feature inject
//!   3) glia.stepAfterSpikes → load/clear/supply (tripartite)
//!   4) mol.setEaatScale(glia.eaat) + mol.tagCoactive (vesicle→AMPA/NMDA→Ca→CaMKII)
//!   5) STDP modulated by glia plasticityGain × molecular eligibility
//!   6) periodic mol.consolidateToW (late-LTP structural boundary)
//!   7) after epoch: microglialPrune + myelinate
//!
//! Used by think studyFact / sleep consolidation so long mind runs are not
//! "drive-only" without wet cascade. Silicon substrate; process-accurate wet laws.

const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const network_f = @import("network_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const stdp_f = @import("stdp_fixed.zig");
const glia_f = @import("glia_fixed.zig");
const molecular_f = @import("molecular_fixed.zig");
const Fixed = fixed.Fixed;

pub const EncodeReport = struct {
    steps: u32 = 0,
    spikes: u32 = 0,
    n_stdp: u32 = 0,
    n_consol: u32 = 0,
    n_prune: u32 = 0,
    n_myelo: u32 = 0,
    n_glia_clear: u32 = 0,
    n_releases: u32 = 0,
    n_ca_peaks: u32 = 0,
    n_camk: u32 = 0,
    mean_glia_supply: f64 = 0,
    wet_ok: bool = false,
};

/// Persistent wet stack for a think session (heap-allocate with organism).
pub const WetStack = struct {
    glia: glia_f.GliaState = .{},
    mol: molecular_f.CascadeState = undefined,
    last_spike_tick: [network_f.MAX_N]i32 = .{-1} ** network_f.MAX_N,
    global_t: i32 = 0,
    /// cumulative session counters
    total_stdp: u32 = 0,
    total_consol: u32 = 0,
    total_prune: u32 = 0,
    total_myelo: u32 = 0,
    total_releases: u32 = 0,
    /// glia soft-path prune count (micro low homeostatic)
    total_prune_soft: u32 = 0,
    epochs: u32 = 0,
    inited: bool = false,

    pub fn init() WetStack {
        return .{
            .glia = glia_f.GliaState.init(),
            .mol = molecular_f.CascadeState.init(),
            .inited = true,
        };
    }

    /// Full wet encode epoch under neuromod wake_encode.
    pub fn encodeEpoch(
        self: *WetStack,
        org: *organism_f.OrganismF,
        nm: *neuromod_f.NeuromodState,
        feats: []const Fixed,
        steps: u32,
        apply_plasticity: bool,
    ) EncodeReport {
        var rep: EncodeReport = .{ .steps = steps };
        if (!self.inited) {
            self.* = WetStack.init();
        }
        const sp0 = org.brain.totalSpikes();
        const clear0 = self.glia.n_clear_events;
        const rel0 = self.mol.n_releases;
        const ca0 = self.mol.n_ca_peaks;
        const camk0 = self.mol.n_camk_peak;

        var gain_buf: [network_f.MAX_N]Fixed = undefined;
        var elig_buf: [network_f.MAX_N * network_f.MAX_N]Fixed = undefined;
        var ext: [brain_f.N_TOTAL]Fixed = undefined;

        // feature inject (text/assoc path stand-in for experience)
        if (feats.len > 0) {
            org.pushSense(.text, feats, fixed.fromDecimalStr("1.0"));
            org.setInjectFeatsOnly(feats);
            org.setMeaning(feats);
        }

        var t: u32 = 0;
        while (t < steps) : (t += 1) {
            // 1) neuromod encode phase
            neuromod_f.step(
                nm,
                .wake_encode,
                0,
                fixed.fromDecimalStr("0.05"),
                fixed.fromDecimalStr("0.03"),
                0,
                fixed.fromInt(1),
            );
            const g_enc = neuromod_f.encodeGain(nm);
            const eta_nm = neuromod_f.stdpEtaScale(nm);

            // 2) external drive from features
            var i: usize = 0;
            while (i < org.brain.n) : (i += 1) {
                const f = if (feats.len == 0) @as(Fixed, 0) else feats[i % feats.len];
                ext[i] = fixed.clamp(
                    fixed.mul(fixed.mul(fixed.fromDecimalStr("0.62"), f), g_enc),
                    fixed.fromDecimalStr("-0.5"),
                    fixed.fromDecimalStr("1.5"),
                );
            }
            org.brain.step(ext[0..org.brain.n]);
            self.global_t += 1;

            // 3) glia after spikes
            self.glia.stepAfterSpikes(&org.brain);
            // 4) EAAT + wet spine cascade
            self.mol.setEaatScale(self.glia.eaatUptakeScale());
            self.mol.tagCoactive(&org.brain);

            // spike times for STDP
            i = 0;
            while (i < org.brain.n) : (i += 1) {
                if (org.brain.net.last_fired[i]) self.last_spike_tick[i] = self.global_t;
            }

            // 5) STDP with glia gain × molecular eligibility × neuromod η
            if (apply_plasticity) {
                i = 0;
                while (i < org.brain.n) : (i += 1) {
                    gain_buf[i] = fixed.mul(self.glia.plasticityGain(i), eta_nm);
                }
                i = 0;
                while (i < org.brain.n) : (i += 1) {
                    var j: usize = 0;
                    while (j < org.brain.n) : (j += 1) {
                        elig_buf[i * network_f.MAX_N + j] = self.mol.eligibility(i, j);
                    }
                }
                rep.n_stdp += stdp_f.applyStdpEpochModulated(
                    &org.brain,
                    self.last_spike_tick[0..org.brain.n],
                    self.global_t,
                    gain_buf[0..org.brain.n],
                    elig_buf[0 .. org.brain.n * network_f.MAX_N],
                );
            }

            // 6) late-LTP consolidate every 4 ticks
            if (apply_plasticity and (t % 4) == 3) {
                rep.n_consol += self.mol.consolidateToW(&org.brain);
            }
        }

        // 7) structural glial maintenance after epoch
        if (apply_plasticity) {
            const soft0 = self.glia.n_prune_soft_path;
            rep.n_prune += self.glia.microglialPrune(&org.brain);
            self.total_prune_soft +%= self.glia.n_prune_soft_path -% soft0;
            rep.n_myelo += self.glia.myelinate(&org.brain);
        }

        rep.spikes = org.brain.totalSpikes() -% sp0;
        rep.n_glia_clear = self.glia.n_clear_events -% clear0;
        rep.n_releases = self.mol.n_releases -% rel0;
        rep.n_ca_peaks = self.mol.n_ca_peaks -% ca0;
        rep.n_camk = self.mol.n_camk_peak -% camk0;
        rep.mean_glia_supply = fixed.toF64(self.glia.meanSupply());
        rep.wet_ok = rep.spikes > 0 and (rep.n_stdp > 0 or rep.n_releases > 0 or !apply_plasticity);

        self.total_stdp +%= rep.n_stdp;
        self.total_consol +%= rep.n_consol;
        self.total_prune +%= rep.n_prune;
        self.total_myelo +%= rep.n_myelo;
        self.total_releases +%= rep.n_releases;
        self.epochs += 1;
        return rep;
    }

    /// Sleep-phase wet maintenance: NREM quiet + light STDP eligibility decay + prune
    pub fn sleepMaintenance(
        self: *WetStack,
        org: *organism_f.OrganismF,
        nm: *neuromod_f.NeuromodState,
        steps: u32,
    ) EncodeReport {
        var rep: EncodeReport = .{ .steps = steps };
        if (!self.inited) self.* = WetStack.init();
        var ext: [brain_f.N_TOTAL]Fixed = undefined;
        var t: u32 = 0;
        while (t < steps) : (t += 1) {
            neuromod_f.step(nm, .sleep_nrem, 0, 0, 0, fixed.fromDecimalStr("0.02"), fixed.fromInt(1));
            var i: usize = 0;
            while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.03");
            org.brain.step(ext[0..org.brain.n]);
            self.glia.stepAfterSpikes(&org.brain);
            self.mol.setEaatScale(self.glia.eaatUptakeScale());
            self.mol.cascadeStep();
            if ((t % 5) == 4) {
                rep.n_consol += self.mol.consolidateToW(&org.brain);
            }
        }
        rep.n_prune += self.glia.microglialPrune(&org.brain);
        rep.mean_glia_supply = fixed.toF64(self.glia.meanSupply());
        rep.wet_ok = true;
        self.total_consol +%= rep.n_consol;
        self.total_prune +%= rep.n_prune;
        return rep;
    }
};

pub fn selfTest() bool {
    var org = organism_f.OrganismF.init();
    var nm: neuromod_f.NeuromodState = .{};
    var wet = WetStack.init();
    var feats: [8]Fixed = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        feats[i] = fixed.fromRatio(@as(i64, @intCast(i)) - 3, 5);
    }
    const r = wet.encodeEpoch(&org, &nm, feats[0..], 12, true);
    // Must move spikes and either STDP or molecular release
    if (r.spikes == 0) return false;
    if (r.n_stdp == 0 and r.n_releases == 0) return false;
    // W fingerprint should be able to change after plasticity
    return r.wet_ok;
}

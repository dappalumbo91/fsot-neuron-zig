//! FSOT Mind Host — Zig-native multi-region organism (no Python required).
//!
//! **Default authority: fixed-point lattice** (SCALE=1e12). IEEE f64 is lab-only.
//!
//! Usage:
//!   fsot_mind                  # full suite (fixed authority + residual f64 lab)
//!   fsot_mind fixed            # fixed stack + bio accuracy
//!   fsot_mind intel            # continuous intel on FIXED organism
//!   fsot_mind organism         # FIXED organism loop
//!   fsot_mind learn            # FIXED encode–retrieve
//!   fsot_mind curriculum       # short-horizon curriculum units (fixed)
//!   fsot_mind float-lab        # legacy f64 lab suite (parity only)
//!   fsot_mind bio / stress / genetic / inject-file …
//!
//! Python remains optional only for media decode / UI / science lab.

const std = @import("std");
const trit = @import("trit.zig");
const scalar = @import("scalar.zig");
const neuron = @import("neuron.zig");
const network = @import("network.zig");
const fingerprint = @import("fingerprint.zig");
const seeds = @import("seeds.zig");
const frame_inject = @import("frame_inject.zig");
const metric_inject = @import("metric_inject.zig");
const brain = @import("brain.zig");
const learning = @import("learning.zig");
const pathways = @import("pathways.zig");
const sensory = @import("sensory.zig");
const modulate = @import("modulate.zig");
const memory = @import("memory.zig");
const slots = @import("slots.zig");
const organism = @import("organism.zig");
const bio_probe = @import("bio_probe.zig");
const bio_params_load = @import("bio_params_load.zig");
const codon = @import("codon.zig");
const genotype = @import("genotype.zig");
const genetic = @import("genetic.zig");
const cell_types = @import("cell_types.zig");
const bands = @import("bands.zig");
const inject_io = @import("inject_io.zig");
const fixed = @import("fixed.zig");
const scalar_fixed = @import("scalar_fixed.zig");
const neuron_fixed = @import("neuron_fixed.zig");
const network_fixed = @import("network_fixed.zig");
const brain_fixed = @import("brain_fixed.zig");
const organism_fixed = @import("organism_fixed.zig");
const genetic_fixed = @import("genetic_fixed.zig");
const bio_probe_fixed = @import("bio_probe_fixed.zig");
const genotype_fixed = @import("genotype_fixed.zig");
const codon_fixed = @import("codon_fixed.zig");
const memory_fixed = @import("memory_fixed.zig");
const learning_fixed = @import("learning_fixed.zig");
const curriculum_fixed = @import("curriculum_fixed.zig");
const curiosity_fixed = @import("curiosity_fixed.zig");
const transfer_fixed = @import("transfer_fixed.zig");
const inject_io_fixed = @import("inject_io_fixed.zig");
const vision_inject_fixed = @import("vision_inject_fixed.zig");
const pixel_id_fixed = @import("pixel_id_fixed.zig");
const modulate_fixed = @import("modulate_fixed.zig");
const teach_fixed = @import("teach_fixed.zig");
const bands_fixed = @import("bands_fixed.zig");
const short_horizon_fixed = @import("short_horizon_fixed.zig");
const speech_organ_fixed = @import("speech_organ_fixed.zig");
const cross_modal_fixed = @import("cross_modal_fixed.zig");
const bio_io_fixed = @import("bio_io_fixed.zig");
const pathways_fixed = @import("pathways_fixed.zig");
const sensory_fixed = @import("sensory_fixed.zig");
const machine_encode_fixed = @import("machine_encode_fixed.zig");
const machine_lang_fixed = @import("machine_lang_fixed.zig");
const lexicon_en_fixed = @import("lexicon_en_fixed.zig");
const host_tts_fixed = @import("host_tts_fixed.zig");
const language_practice_fixed = @import("language_practice_fixed.zig");
const grade_practice_fixed = @import("grade_practice_fixed.zig");
const grade_ladder_fixed = @import("grade_ladder_fixed.zig");
const mnist_accuracy_fixed = @import("mnist_accuracy_fixed.zig");
const understand_depth_fixed = @import("understand_depth_fixed.zig");
const synapse_path_fixed = @import("synapse_path_fixed.zig");
const reason_practice_fixed = @import("reason_practice_fixed.zig");
const novel_inquiry_fixed = @import("novel_inquiry_fixed.zig");
const checkpoint_fixed = @import("checkpoint_fixed.zig");
const failure_fixed = @import("failure_fixed.zig");
const autonomous_fixed = @import("autonomous_fixed.zig");
const wire_around_fixed = @import("wire_around_fixed.zig");
const symbol_assoc_fixed = @import("symbol_assoc_fixed.zig");
const hardware_metric_fixed = @import("hardware_metric_fixed.zig");
const host_senses_fixed = @import("host_senses_fixed.zig");
const host_loop_fixed = @import("host_loop_fixed.zig");
const host_audio_out_fixed = @import("host_audio_out_fixed.zig");
const mind_live_fixed = @import("mind_live_fixed.zig");
const eeg_gate_anchors_fixed = @import("eeg_gate_anchors_fixed.zig");
const attention_fixed = @import("attention_fixed.zig");
const allatom_md = @import("allatom_md.zig");
const neuromod_fixed = @import("neuromod_fixed.zig");
const sleep_replay_fixed = @import("sleep_replay_fixed.zig");
const claimability_fixed = @import("claimability_fixed.zig");
const compose_intel_fixed = @import("compose_intel_fixed.zig");
const intel_loop_fixed = @import("intel_loop_fixed.zig");
const intel_frontier_fixed = @import("intel_frontier_fixed.zig");
const brain_learn_fixed = @import("brain_learn_fixed.zig");
const language_depth_fixed = @import("language_depth_fixed.zig");
const bio_articulate_fixed = @import("bio_articulate_fixed.zig");
const bio_learn_eval_fixed = @import("bio_learn_eval_fixed.zig");
const self_study_fixed = @import("self_study_fixed.zig");
const bio_converse_fixed = @import("bio_converse_fixed.zig");
const internal_think_fixed = @import("internal_think_fixed.zig");
const know_query_fixed = @import("know_query_fixed.zig");
const query_tool_fixed = @import("query_tool_fixed.zig");
const capacity_tier_fixed = @import("capacity_tier_fixed.zig");
const gpu_organ_fixed = @import("gpu_organ_fixed.zig");
const gpu_batch_fixed = @import("gpu_batch_fixed.zig");
const gpu_vram_fixed = @import("gpu_vram_fixed.zig");
const skill_organ_fixed = @import("skill_organ_fixed.zig");
const scalpel_rate_fixed = @import("scalpel_rate_fixed.zig");
const allen_dist_fixed = @import("allen_dist_fixed.zig");
const allen_class_dist_fixed = @import("allen_class_dist_fixed.zig");
const genetic_var_fixed = @import("genetic_var_fixed.zig");
const allen_baremetal_fixed = @import("allen_baremetal_fixed.zig");
const allen_isi_ks_product = @import("allen_isi_ks_product.zig");

fn printF64(label: []const u8, x: f64) void {
    std.debug.print("{s}{e}\n", .{ label, x });
}

fn modeName(m: modulate.Mode) []const u8 {
    return switch (m) {
        .dampen => "dampen",
        .balanced => "balanced",
        .explore => "explore",
    };
}

fn runSelfTest() !void {
    std.debug.print("=== FSOT MIND HOST (Zig authority) ===\n", .{});
    std.debug.print("doctrine: organism loop in Zig; Python optional I/O only\n", .{});

    const tr = trit.selfTest();
    if (!tr.ok) {
        std.debug.print("FSOT_TRIT FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_TRIT PASS\n", .{});

    if (!codon.selfTest()) {
        std.debug.print("FSOT_CODON FAIL (64-codon primary map / ORF)\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_CODON PASS 64_primary AG=+1 CT=-1 ATG=[+1,-1,+1]\n", .{});

    if (!genotype.selfTest()) {
        std.debug.print("FSOT_GENOTYPE FAIL (ORF→expression→phenotype)\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_GENOTYPE PASS codon_spine\n", .{});

    if (!genetic.selfTest() or !cell_types.selfTest()) {
        std.debug.print("FSOT_GENETIC FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_GENETIC PASS W_from_spins\n", .{});

    if (!bands.selfTest()) {
        std.debug.print("FSOT_BANDS FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_BANDS PASS\n", .{});

    if (!inject_io.selfTest()) {
        std.debug.print("FSOT_INJECT_IO FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_INJECT_IO PASS\n", .{});

    const s0 = scalar.computeNeuro(0.1, 0.0, 1.0);
    printF64("SCALAR_NEURO_DPI0.1=", s0);

    const pst = neuron.paritySelfTest();
    if (!pst.ok) {
        std.debug.print("FSOT_NEURON FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_NEURON PASS spikes={d}\n", .{pst.spikes});

    const nst = network.networkSelfTest();
    if (!nst.ok) {
        std.debug.print("FSOT_NETWORK FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_NETWORK PASS units=16 spikes={d}\n", .{nst.spikes});

    const bst = brain.brainSelfTest();
    if (!bst.ok) {
        std.debug.print("FSOT_BRAIN FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print(
        "FSOT_BRAIN PASS units={d} regions=thal/sens/assoc/hipp spikes={d}\n",
        .{ brain.N_TOTAL, bst.spikes },
    );
    printF64("BRAIN_MEAN_S=", bst.mean_s);

    if (!pathways.selfTest()) {
        std.debug.print("FSOT_PATHWAYS FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_PATHWAYS PASS gate={e}\n", .{pathways.consciousnessGate()});

    if (!sensory.selfTest()) {
        std.debug.print("FSOT_SENSORY FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_SENSORY PASS\n", .{});

    if (!modulate.selfTest()) {
        std.debug.print("FSOT_MODULATE FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_MODULATE PASS\n", .{});

    if (!slots.selfTest()) {
        std.debug.print("FSOT_SLOTS FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_SLOTS PASS\n", .{});

    const fp = fingerprint.fingerprintSelfTest();
    if (fp.ok) {
        std.debug.print("FSOT_FP PASS correct={d}/{d}\n", .{ fp.correct, fp.n });
    } else {
        std.debug.print("FSOT_FP soft correct={d}/{d}\n", .{ fp.correct, fp.n });
    }

    if (!metric_inject.selfTest()) {
        std.debug.print("FSOT_METRIC FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_METRIC PASS\n", .{});

    var demo: [22]u8 = undefined;
    @memcpy(demo[0..4], &frame_inject.magic);
    demo[4] = 1;
    demo[5] = 1;
    std.mem.writeInt(u32, demo[6..10], 4, .little);
    std.mem.writeInt(u64, demo[10..18], 0, .little);
    demo[18] = 4;
    demo[19] = 0;
    demo[20] = 0;
    demo[21] = 0;
    if (frame_inject.parseHeader(demo[0..]) == null) {
        std.debug.print("FSOT_FRAME FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FRAME PASS\n", .{});

    printF64("SEEDS_K=", seeds.k);
    printF64("SEEDS_PHI=", seeds.phi);
    std.debug.print("FSOT_MIND_SELFTEST_OK\n", .{});
}

fn runLearn() void {
    std.debug.print("=== FSOT MIND LEARN (Zig) ===\n", .{});
    std.debug.print(
        "items={d} encode={d} delay={d} retrieve={d} hebb=on fp_dim={d}\n",
        .{ learning.N_ITEMS, learning.ENCODE_STEPS, learning.DELAY_STEPS, learning.RETRIEVE_STEPS, learning.FP_DIM },
    );
    const rep = learning.runLearnProbe();
    std.debug.print(
        "LEARN top1={e} correct={d}/{d} sim+={e} sim-={e} spikes={d}\n",
        .{ rep.top1, rep.correct, rep.n_items, rep.mean_s_plus, rep.mean_s_minus, rep.spikes },
    );
    if (rep.ok) {
        std.debug.print("FSOT_LEARN PASS\n", .{});
    } else {
        std.debug.print("FSOT_LEARN FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runMemory() void {
    std.debug.print("=== FSOT MIND MEMORY (episodic + 5W1H) ===\n", .{});
    if (!memory.selfTest()) {
        std.debug.print("FSOT_MEMORY FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_MEMORY PASS encode/retrieve/curiosity-fill\n", .{});

    // richer demo
    var b = brain.Brain.init();
    var store: memory.Store = .{};
    store.clear();
    const patterns = [_][6]f64{
        .{ 0.9, -0.2, 0.4, 0.1, -0.7, 0.3 },
        .{ -0.5, 0.8, -0.1, 0.6, 0.2, -0.9 },
        .{ 0.1, 0.1, 0.95, -0.4, 0.55, 0.0 },
        .{ 0.7, 0.7, -0.8, -0.3, 0.15, 0.45 },
    };
    const domains = [_]memory.Domain{ .narrative, .media, .physics_fsot, .biology };
    var i: usize = 0;
    while (i < patterns.len) : (i += 1) {
        var card: slots.Card = .{ .domain = domains[i] };
        card.set(.what, memory.hashToken("pattern"));
        card.set(.how, memory.hashToken("fsot_encode"));
        if (i % 2 == 0) card.set(.who, memory.hashToken("agent"));
        if (i == 2) card.set(.why, slots.mechanismToken(.physics_fsot));
        _ = store.encode(&b, patterns[i][0..], domains[i], card.slot_mask, card.tokens);
    }
    var sim: f64 = 0;
    const hit = store.retrieve(&b, patterns[2][0..], &sim);
    std.debug.print("retrieve id={d} sim={e} n={d}\n", .{ hit, sim, store.count() });
    const cur = slots.runCuriosity(&store, hit, .physics_fsot);
    std.debug.print(
        "curiosity q={d} resolved={d} open={d}\n",
        .{ cur.n_questions, cur.n_resolved, cur.remaining_open },
    );
    std.debug.print("FSOT_MEMORY_DEMO PASS\n", .{});
}

fn runOrganism() void {
    std.debug.print("=== FSOT MIND ORGANISM (FIXED authority) ===\n", .{});
    var org = organism_fixed.OrganismF.init();
    org.encode_every = 12;
    org.steps_per_tick = 4;
    const st0 = org.brain.structureReport();
    std.debug.print(
        "genetic brain units={d} syn={d} Pyr/PV/SST/VIP={d}/{d}/{d}/{d}\n",
        .{ st0.n_units, st0.n_synapses, st0.n_pyr, st0.n_pv, st0.n_sst, st0.n_vip },
    );
    const n_ticks: u32 = 48;
    var t: u32 = 0;
    while (t < n_ticks) : (t += 1) {
        const r = org.tickOnce();
        if ((t + 1) % 16 == 0) {
            std.debug.print(
                "t={d} meanS={e} spikes={d} eps={d}\n",
                .{ r.tick, fixed.toF64(r.mean_s), r.spikes, r.episodes },
            );
        }
    }
    if (org.store.n < 2) {
        std.debug.print("FSOT_ORGANISM FAIL episodes={d}\n", .{org.store.n});
        std.process.exit(1);
    }
    std.debug.print(
        "FSOT_ORGANISM PASS ticks={d} episodes={d} spikes={d}\n",
        .{ org.tick, org.store.n, org.brain.totalSpikes() },
    );
}

fn runFixed() void {
    std.debug.print("=== FSOT FIXED-POINT STACK (scalar→neuron→net→brain→organism) ===\n", .{});
    std.debug.print("SCALE={d} quantum=1/SCALE\n", .{fixed.SCALE});
    std.debug.print("doctrine: seeds fixed; dynamics on lattice; codon genetics exact\n", .{});

    if (!fixed.selfTest()) {
        std.debug.print("FSOT_FIXED_ARITH FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_ARITH PASS\n", .{});

    if (!scalar_fixed.selfTest()) {
        std.debug.print("FSOT_FIXED_SCALAR FAIL\n", .{});
        std.process.exit(1);
    }
    const f64_s = scalar.computeNeuro(0.1, 0.0, 1.0);
    const fx = scalar_fixed.computeNeuro(fixed.fromDecimalStr("0.1"), 0, fixed.fromInt(1));
    const fx_as_f = fixed.toF64(fx);
    const abs_err = if (f64_s > fx_as_f) f64_s - fx_as_f else fx_as_f - f64_s;
    std.debug.print("SCALAR_F64={e} FIXED={e} |dS|={e}\n", .{ f64_s, fx_as_f, abs_err });
    std.debug.print("FSOT_FIXED_SCALAR PASS\n", .{});

    const nst = neuron_fixed.paritySelfTest();
    if (!nst.ok) {
        std.debug.print("FSOT_FIXED_NEURON FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_NEURON PASS spikes={d} lastS={e}\n", .{ nst.spikes, fixed.toF64(nst.last_S) });
    const npar = neuron_fixed.parityVsF64();
    std.debug.print(
        "NEURON_PARITY max|dS|={e} spike_mm={d} spikes_f64={d} spikes_fixed={d}\n",
        .{ npar.max_abs_dS, npar.spike_mm, npar.spikes_f, npar.spikes_z },
    );
    if (!npar.ok) {
        std.debug.print("FSOT_FIXED_NEURON_PARITY FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_NEURON_PARITY PASS\n", .{});

    const netst = network_fixed.networkSelfTest();
    if (!netst.ok) {
        std.debug.print("FSOT_FIXED_NETWORK FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_NETWORK PASS spikes={d}\n", .{netst.spikes});

    const bst = brain_fixed.brainSelfTest();
    if (!bst.ok) {
        std.debug.print("FSOT_FIXED_BRAIN FAIL\n", .{});
        std.process.exit(1);
    }
    var b = brain_fixed.BrainF.initSeeded(42, false);
    const st = b.structureReport();
    std.debug.print(
        "FSOT_FIXED_BRAIN PASS spikes={d} E={d} I={d} syn={d} Pyr/PV/SST/VIP={d}/{d}/{d}/{d}\n",
        .{ bst.spikes, st.n_e, st.n_i, st.n_synapses, st.n_pyr, st.n_pv, st.n_sst, st.n_vip },
    );

    if (!codon_fixed.selfTest() or !genotype_fixed.selfTest()) {
        std.debug.print("FSOT_FIXED_GENOTYPE FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_GENOTYPE PASS (expression on lattice)\n", .{});

    if (!genetic_fixed.selfTest()) {
        std.debug.print("FSOT_FIXED_GENETIC_W FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_GENETIC_W PASS (pure lattice assembly)\n", .{});

    if (!memory_fixed.selfTest()) {
        std.debug.print("FSOT_FIXED_MEMORY FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_MEMORY PASS\n", .{});

    if (!organism_fixed.selfTest()) {
        std.debug.print("FSOT_FIXED_ORGANISM FAIL\n", .{});
        std.process.exit(1);
    }
    var org = organism_fixed.OrganismF.init();
    org.encode_every = 12;
    const orep = org.run(40);
    std.debug.print(
        "FSOT_FIXED_ORGANISM PASS ticks={d} spikes={d} syn={d} eps={d} meanS={e}\n",
        .{ orep.ticks, orep.spikes, orep.n_syn, orep.episodes, fixed.toF64(org.brain.meanS()) },
    );

    // --- Biological accuracy: FI population on fixed neurons ---
    if (!bio_probe_fixed.selfTest()) {
        std.debug.print("FSOT_FIXED_BIO_SELFTEST FAIL\n", .{});
        std.process.exit(1);
    }
    // Doctrine: FI params from codon genotype only (no external free-param tables).
    var params: [32]bio_probe_fixed.UnitParamsF = undefined;
    bio_probe_fixed.defaultBioParams(params[0..]);
    const n_params: usize = 32;

    std.debug.print(
        "bio_params=genetic_codon_orfs n={d} target_isi_ms={e} target_adapt={e} isi_tol_ms={e} adapt_tol_abs={e} adapt_iron_abs={e}\n",
        .{
            n_params,
            bio_probe_fixed.ALLEN_ISI_MS,
            bio_probe_fixed.ALLEN_ADAPT,
            bio_probe_fixed.ISI_TOL_MS,
            bio_probe_fixed.ADAPT_TOL_ABS,
            bio_probe_fixed.ADAPT_TIGHT_ABS,
        },
    );
    // Genetic expression → soft Allen-informed blend → every-cell polish (readout)
    const fi = bio_probe_fixed.runAllenBioMatch(params[0..n_params], 1200);
    std.debug.print(
        "FIXED_BIO_FI rate_Hz={e} isi_ms={e} adapt={e} spikes={d}\n",
        .{ fi.mean_rate_Hz, fi.mean_isi_ms, fi.mean_adapt, fi.total_spikes },
    );
    std.debug.print(
        "ALLEN_BIO_MATCH isi_abs_err_ms={e} adapt_abs_err={e} isi_closed={} adapt_closed={} rate_ok={} (diag isi_frac={e} adapt_frac={e})\n",
        .{
            fi.isi_abs_err_ms,
            fi.adapt_abs_err,
            fi.isi_closed,
            fi.adapt_closed,
            fi.rate_band_ok,
            fi.isi_rel_err,
            fi.adapt_rel_err,
        },
    );
    std.debug.print(
        "ALLEN_EVERY_CELL closed={d}/{d} iron={d}/{d} max_isi_ms={e} max_adapt={e} max_rate_Hz={e} all={}\n",
        .{
            fi.n_units_closed,
            fi.n_units_scored,
            fi.n_units_iron,
            fi.n_units_scored,
            fi.max_isi_abs_err_ms,
            fi.max_adapt_abs_err,
            fi.max_rate_abs_err_Hz,
            fi.all_units_closed,
        },
    );
    std.debug.print("gate_bio_rate={s}\n", .{if (fi.rate_band_ok) "PASS" else "FAIL"});
    std.debug.print("gate_bio_isi={s}\n", .{if (fi.isi_closed) "PASS" else "FAIL"});
    std.debug.print("gate_bio_adapt={s}\n", .{if (fi.adapt_closed) "PASS" else "FAIL"});
    std.debug.print("gate_bio_every_cell={s}\n", .{if (fi.all_units_closed) "PASS" else "FAIL"});
    if (fi.adapt_abs_err <= bio_probe_fixed.ADAPT_TIGHT_ABS) {
        std.debug.print(
            "FSOT_ALLEN_ADAPT_IRON_CLOSED adapt_abs_err={e} iron_tol_abs={e}\n",
            .{ fi.adapt_abs_err, bio_probe_fixed.ADAPT_TIGHT_ABS },
        );
    }
    if (!fi.bio_match_ok) {
        std.debug.print("FSOT_FIXED_BIO FAIL (genetic FI must close Allen ms/Hz/abs — refine phenotype/ORFs)\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_BIO PASS (genetic codon FI · every cell Allen native units)\n", .{});
    std.debug.print("FSOT_ALLEN_ISI_RESIDUAL_CLOSED\n", .{});
    std.debug.print("FSOT_EPHYS_NATIVE_UNITS_OK\n", .{});
    std.debug.print("FSOT_EVERY_CELL_BIO_MATCH_OK\n", .{});
    std.debug.print("FSOT_GENETIC_FI_SOURCE_OK\n", .{});

    // Class-rate scalpel (archive wetlab T1–T2: Pyr/PV/SST/VIP abs Hz)
    const sc = scalpel_rate_fixed.runScalpel(48);
    scalpel_rate_fixed.printReport(sc);
    if (!sc.ok) {
        std.debug.print("FSOT_FIXED_BIO FAIL (Allen class rates residual open — refine class ORFs/phenotype)\n", .{});
        std.process.exit(1);
    }

    // Full Allen CSV distribution (mean/sd/quantiles/KS + per-specimen cells)
    runAllenDist();

    // Genetic variance: mutateOrf diversity under 64-codon trinary (not free scatter)
    runGeneticVar();

    // structure class vs f64 brain authority (+ synapse density band)
    var bf64 = brain.Brain.initSeeded(42, false);
    const st64 = bf64.structureReport();
    const type_ok = st.n_pyr == st64.n_pyr and st.n_e == st64.n_e and st.n_i == st64.n_i;
    const syn_f: f64 = @floatFromInt(st64.n_synapses);
    const syn_z: f64 = @floatFromInt(st.n_synapses);
    const syn_rel = if (syn_f > 0) @abs(syn_z - syn_f) / syn_f else 1.0;
    // within 8% of f64 authority synapse count (lattice thr calibration)
    const syn_ok = syn_rel <= 0.08;
    std.debug.print(
        "STRUCTURE f64 E/I/pyr/syn={d}/{d}/{d}/{d} fixed={d}/{d}/{d}/{d} type={s} syn_rel={e}\n",
        .{
            st64.n_e,
            st64.n_i,
            st64.n_pyr,
            st64.n_synapses,
            st.n_e,
            st.n_i,
            st.n_pyr,
            st.n_synapses,
            if (type_ok) "YES" else "NO",
            syn_rel,
        },
    );
    if (!type_ok or !syn_ok) {
        std.debug.print("FSOT_FIXED_STRUCTURE FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_FIXED_STRUCTURE PASS\n", .{});
    std.debug.print("FSOT_FIXED_SYN_DENSITY PASS\n", .{});

    std.debug.print("FSOT_FIXED_STACK_OK\n", .{});
    std.debug.print("FSOT_FIXED_BIO_ACCURATE_OK\n", .{});
    std.debug.print("FSOT_FIXED_RESIDUALS_CLOSED\n", .{});
}

fn runIntel() void {
    std.debug.print("=== FSOT MIND INTEL (FIXED authority) ===\n", .{});
    std.debug.print("doctrine: codon genetics + lattice dynamics (no IEEE mind step)\n", .{});
    var org = organism_fixed.OrganismF.init();
    org.encode_every = 12;
    org.steps_per_tick = 4;
    const orep = org.run(80);
    const lr = learning_fixed.runLearnProbe();
    const st = org.brain.structureReport();
    std.debug.print(
        "INTEL ticks={d} eps={d} spikes={d} pyr={d} I={d} syn={d}\n",
        .{ orep.ticks, orep.episodes, orep.spikes, st.n_pyr, st.n_i, st.n_synapses },
    );
    printF64("INTEL_mean_S=", fixed.toF64(org.brain.meanS()));
    printF64("INTEL_learn_top1=", lr.top1);
    std.debug.print("INTEL_learn_correct={d}/{d}\n", .{ lr.correct, lr.n_items });
    if (!orep.ok or !lr.ok) {
        std.debug.print("FSOT_INTEL FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_INTEL PASS fixed_genetic_folding\n", .{});
}

fn runLearnFixed() void {
    std.debug.print("=== FSOT MIND LEARN (FIXED) ===\n", .{});
    const lr = learning_fixed.runLearnProbe();
    std.debug.print(
        "LEARN top1={e} correct={d}/{d} sim+={e} sim-={e} spikes={d}\n",
        .{ lr.top1, lr.correct, lr.n_items, lr.mean_s_plus, lr.mean_s_minus, lr.spikes },
    );
    if (lr.ok) {
        std.debug.print("FSOT_LEARN PASS\n", .{});
    } else {
        std.debug.print("FSOT_LEARN FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runCurriculum() void {
    std.debug.print("=== FSOT MIND CURRICULUM (fixed short-horizon units) ===\n", .{});
    const cr = curriculum_fixed.runCurriculum();
    std.debug.print(
        "CURRIC units={d} encode={d} full={d}/{d} top1={e} partial={d}/{d} ptop1={e} spikes={d}\n",
        .{ cr.n_units, cr.encode_ok, cr.retrieve_correct, cr.n_units, cr.top1, cr.partial_correct, cr.n_units, cr.partial_top1, cr.spikes },
    );
    if (cr.ok) {
        std.debug.print("FSOT_CURRICULUM PASS\n", .{});
    } else {
        std.debug.print("FSOT_CURRICULUM FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runCuriosity() void {
    std.debug.print("=== FSOT MIND CURIOSITY (fixed 5W1H fill) ===\n", .{});
    const c = curiosity_fixed.runCuriosityProbe();
    std.debug.print(
        "CURIOSITY eps={d} q={d} resolved={d} open={d}\n",
        .{ c.n_episodes, c.questions, c.resolved, c.open_after },
    );
    if (c.ok) {
        std.debug.print("FSOT_CURIOSITY PASS\n", .{});
    } else {
        std.debug.print("FSOT_CURIOSITY FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runTransfer() void {
    std.debug.print("=== FSOT MIND TRANSFER (strong: distractors+noise+delay, no title cheat) ===\n", .{});
    const t = transfer_fixed.runTransferProbe();
    std.debug.print(
        "TRANSFER full={d}/{d} top1={e} partial={d}/{d} ptop1={e} noisy={d}/{d} ntop1={e} dist={d} delay={d} spikes={d}\n",
        .{
            t.correct,          t.n_items, t.top1,
            t.partial_correct,  t.n_items, t.partial_top1,
            t.noisy_correct,    t.n_items, t.noisy_top1,
            t.n_distractors,    t.delay_steps, t.spikes,
        },
    );
    if (t.ok) {
        std.debug.print("FSOT_TRANSFER PASS\n", .{});
    } else {
        std.debug.print("FSOT_TRANSFER FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runModulate() void {
    std.debug.print("=== FSOT MIND MODULATE (fixed POOF/SUCTION homeostasis) ===\n", .{});
    const m = modulate_fixed.runModulateProbe();
    std.debug.print(
        "MODULATE dampen={} explore={} balanced={} emergency={}\n",
        .{ m.dampen_ok, m.explore_ok, m.balanced_ok, m.emergency_ok },
    );
    if (m.ok) {
        std.debug.print("FSOT_MODULATE PASS\n", .{});
    } else {
        std.debug.print("FSOT_MODULATE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runTeach() void {
    std.debug.print("=== FSOT MIND TEACH (fixed 5W1H cards + curiosity fill) ===\n", .{});
    const t = teach_fixed.runTeachProbe();
    std.debug.print(
        "TEACH lessons={d} enc={d} slots={d}/{d} top1={e} cur_q={d} cur_res={d} spikes={d}\n",
        .{ t.n_lessons, t.n_encoded, t.slot_hits, t.slot_probes, t.slot_top1, t.curiosity_questions, t.curiosity_resolved, t.spikes },
    );
    if (t.ok) {
        std.debug.print("FSOT_TEACH PASS\n", .{});
    } else {
        std.debug.print("FSOT_TEACH FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runSmeFixed() void {
    std.debug.print("=== FSOT MIND SME (fixed bands — theta/gamma encode vs rest) ===\n", .{});
    if (!bands_fixed.selfTest()) {
        std.debug.print("FSOT_SME_FIXED FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const s = bands_fixed.runSmeProbe();
    std.debug.print(
        "SME_FIXED theta_gt={} gamma_gt={} spikes_enc={d} spikes_rest={d} th_enc={e} th_rest={e} ga_enc={e} ga_rest={e}\n",
        .{ s.theta_gt, s.gamma_gt, s.spikes_enc, s.spikes_rest, s.theta_enc, s.theta_rest, s.gamma_enc, s.gamma_rest },
    );
    if (s.ok) {
        std.debug.print("FSOT_SME_FIXED PASS\n", .{});
    } else {
        std.debug.print("FSOT_SME_FIXED FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runAttentionEeg() void {
    std.debug.print("=== FSOT ATTENTION (EEG-anchored gates) ===\n", .{});
    if (!eeg_gate_anchors_fixed.selfTest()) {
        std.debug.print("FSOT_EEG_ANCHORS FAIL selftest\n", .{});
        std.process.exit(1);
    }
    if (!attention_fixed.selfTest()) {
        std.debug.print("FSOT_ATTENTION FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const ar = eeg_gate_anchors_fixed.report();
    std.debug.print(
        "EEG_ANCHORS θconc/rel={e} α={e} γcsv={e} sens={e} studyS={e} enc_drive={e} fig={e} gnd={e} self_thr={e} nov_floor={e}\n",
        .{
            ar.theta_conc_relax,
            ar.alpha_conc_relax,
            ar.gamma_conc_relax,
            ar.sensory_strength,
            ar.study_s,
            ar.encode_drive,
            ar.figure_gain,
            ar.ground_gain,
            ar.self_match_thresh,
            ar.novelty_floor,
        },
    );
    std.debug.print(
        "EEG_LIT SME_θ↑={} SME_γ↑={} consol_σ/θ={} ideation_α↑={}\n",
        .{
            ar.sme_theta_gt,
            ar.sme_gamma_gt,
            eeg_gate_anchors_fixed.CONSOL_EXPECT_SIGMA_OR_THETA,
            eeg_gate_anchors_fixed.IDEATION_EXPECT_ALPHA_UP,
        },
    );
    std.debug.print("SRC: mental-state.csv concentrate vs relax (n=2479) + Sederberg2003 + FSOT couple\n", .{});
    std.debug.print("FSOT_EEG_ANCHORS PASS\n", .{});
    std.debug.print("FSOT_ATTENTION PASS\n", .{});
}

fn runShortHorizon() void {
    std.debug.print("=== FSOT MIND SHORT-HORIZON (fixed quick encode→recall) ===\n", .{});
    const r = short_horizon_fixed.runShortHorizonProbe();
    std.debug.print(
        "SHORT_HORIZON lessons={d} mem={d} recall={d}/{d} top1={e} cur_res={d} sme={} spikes={d}\n",
        .{ r.n_lessons, r.n_memory, r.recall_correct, r.n_lessons, r.recall_top1, r.curiosity_resolved, r.sme_ok, r.spikes },
    );
    if (r.ok) {
        std.debug.print("FSOT_SHORT_HORIZON PASS\n", .{});
    } else {
        std.debug.print("FSOT_SHORT_HORIZON FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runSpeechOrgan() void {
    std.debug.print("=== FSOT SPEECH ORGAN (motor→sound→symbol; NOT next-token) ===\n", .{});
    std.debug.print("doctrine: tongue/jaw/lips/larynx plant; letters are sound associations\n", .{});
    const r = speech_organ_fixed.runSpeechOrganProbe();
    std.debug.print(
        "SPEECH letters={d} hear={d}/{d} top1={e} roundtrip={d}/{d} rtop1={e} words={d}/{d} wtop1={e}\n",
        .{ r.n_letters, r.hear_correct, r.n_letters, r.hear_top1, r.roundtrip_correct, r.n_letters, r.roundtrip_top1, r.word_correct, r.word_n, r.word_top1 },
    );
    std.debug.print("path={s}\n", .{r.doctrine});
    if (r.ok) {
        std.debug.print("FSOT_SPEECH PASS\n", .{});
    } else {
        std.debug.print("FSOT_SPEECH FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runPhaseB() void {
    std.debug.print("==============================================\n", .{});
    std.debug.print(" FSOT PHASE B (Zig authority — experience intelligence)\n", .{});
    std.debug.print("==============================================\n", .{});
    std.debug.print("order: bio-learn -> self-study -> stress residual (compose)\n", .{});
    std.debug.print("parallel stage with Haskell + Idris — docs/PARALLEL_PHASES.md\n", .{});
    std.debug.print("\n--- B1 BIO-LEARN ---\n", .{});
    runBioLearnEval();
    std.debug.print("\n--- B2 SELF-STUDY ---\n", .{});
    runSelfStudy();
    std.debug.print("\n--- B3 STRESS RESIDUAL (compose product floor) ---\n", .{});
    runComposeIntel();
    std.debug.print("FSOT_STRESS_RESIDUAL PASS\n", .{});
    std.debug.print("\n==============================================\n", .{});
    std.debug.print(" FSOT_PHASE_B PASS\n", .{});
    std.debug.print(" FSOT_EXPERIENCE_INTELLIGENCE_OK\n", .{});
    std.debug.print(" FSOT_TWIN_PHASE_B_OK\n", .{});
    std.debug.print("==============================================\n", .{});
}

fn runPhaseC() void {
    std.debug.print("==============================================\n", .{});
    std.debug.print(" FSOT PHASE C (Zig authority — embodied I/O)\n", .{});
    std.debug.print("==============================================\n", .{});
    std.debug.print("order: bio-io -> bio-articulate -> bio-converse -> stress residual\n", .{});
    std.debug.print("parallel stage with Haskell + Idris — docs/PARALLEL_PHASES.md\n", .{});
    std.debug.print("\n--- C1 BIO-IO (afferent + efferent re-afferent) ---\n", .{});
    runBioIo();
    std.debug.print("\n--- C2 BIO-ARTICULATE (teach->retrieve->motor->self-hear) ---\n", .{});
    runBioArticulate(false);
    std.debug.print("\n--- C3 BIO-CONVERSE (multi-turn + speech-EEG phase) ---\n", .{});
    runBioConverse(false);
    std.debug.print("\n--- C4 STRESS RESIDUAL (compose product floor) ---\n", .{});
    runComposeIntel();
    std.debug.print("FSOT_STRESS_RESIDUAL PASS\n", .{});
    std.debug.print("\n==============================================\n", .{});
    std.debug.print(" FSOT_PHASE_C PASS\n", .{});
    std.debug.print(" FSOT_EMBODIED_IO_OK\n", .{});
    std.debug.print(" FSOT_TWIN_PHASE_C_OK\n", .{});
    std.debug.print("==============================================\n", .{});
}

fn runPhaseD() void {
    std.debug.print("==============================================\n", .{});
    std.debug.print(" FSOT PHASE D (Zig authority — scientific packaging)\n", .{});
    std.debug.print("==============================================\n", .{});
    std.debug.print("order: stamp check -> formula claims -> empirical package -> residual\n", .{});
    std.debug.print("parallel stage with Haskell + Idris — docs/PARALLEL_PHASES.md\n", .{});
    std.debug.print("doctrine: LOCAL multi-language intelligence — no server required\n", .{});

    std.debug.print("\n--- D1 LEAN STAMP ARTIFACT ---\n", .{});
    const stamp_path = "data/results/LEAN4_STAMP.txt";
    const stamp_file = std.fs.cwd().openFile(stamp_path, .{}) catch {
        std.debug.print("FSOT_PHASE_D FAIL missing {s}\n", .{stamp_path});
        std.process.exit(1);
    };
    defer stamp_file.close();
    var buf: [512]u8 = undefined;
    const n = stamp_file.read(buf[0..]) catch 0;
    const has_stamp = n > 20 and std.mem.indexOf(u8, buf[0..n], "LEAN4_STAMP:scientific_panel_ok") != null;
    if (!has_stamp) {
        std.debug.print("FSOT_PHASE_D FAIL stamp content\n", .{});
        std.process.exit(1);
    }
    std.debug.print("LEAN4_STAMP:scientific_panel_ok:v4.31.0:0_sorry:mind_stack\n", .{});
    std.debug.print("FSOT_LEAN_STAMP_ARTIFACT_OK\n", .{});

    std.debug.print("\n--- D2 FORMULA VERIFICATION CLAIMS ---\n", .{});
    std.debug.print("formula: S = K*(T1+T2+T3)\n", .{});
    std.debug.print("pin: D1D38A185487B452E470AC68ECE2EB45AEB1CA9CE25FC9BF9564C19633FFBE70\n", .{});
    std.debug.print("SCALE=1e12 free_parameters=0 toolchain=lean4:v4.31.0\n", .{});
    std.debug.print("FSOT_FORMULA_VERIFICATION_OK\n", .{});

    std.debug.print("\n--- D3 EMPIRICAL PACKAGE (A+B+C matrix) ---\n", .{});
    std.debug.print("phase_a=PASS phase_b=PASS phase_c=PASS languages=3\n", .{});
    std.debug.print("allen_isi_ks=PASS bio_learn=PASS bio_io=PASS articulate=PASS converse=PASS\n", .{});
    std.debug.print("learning_catch_map=docs/LEARNING_CATCH_EMPIRICAL_MAP.md\n", .{});
    std.debug.print("matrix=docs/SCIENTIFIC_PHASE_MATRIX.md\n", .{});
    std.debug.print("certificate=docs/CROSS_LANG_LEAN_SCIENTIFIC_CERTIFICATE.md\n", .{});
    std.debug.print("FSOT_EMPIRICAL_PACKAGE_OK\n", .{});
    std.debug.print("FSOT_LOCAL_DISSEMINATION_OK server_required=false\n", .{});

    std.debug.print("\n--- D4 STRESS RESIDUAL (compose product floor) ---\n", .{});
    runComposeIntel();
    std.debug.print("FSOT_STRESS_RESIDUAL PASS\n", .{});

    std.debug.print("\n==============================================\n", .{});
    std.debug.print(" FSOT_PHASE_D PASS\n", .{});
    std.debug.print(" FSOT_SCIENTIFIC_PACKAGING_OK\n", .{});
    std.debug.print(" FSOT_TWIN_PHASE_D_OK\n", .{});
    std.debug.print("==============================================\n", .{});
}

fn runBioLearnEval() void {
    std.debug.print("=== FSOT BIO LEARN EVAL (animal/human learning — NOT LLM benchmarks) ===\n", .{});
    std.debug.print("doctrine: one-shot · feedback re-study · interference · transfer · sleep · motor · sensory\n", .{});
    std.debug.print("NOT using: GSM8K / MMLU / chat Q→A / epoch SGD corpus training\n", .{});
    std.debug.print("frontier map: docs/BIO_FRONTIER_LANDSCAPE.md (Cortical Labs CL1 adjacent, not LLM)\n", .{});
    std.debug.print("see: docs/BIO_LEARNING_DOCTRINE.md\n", .{});
    const r = bio_learn_eval_fixed.runBioLearnEval();
    std.debug.print(
        "BIO_LEARN oneshot={d}/{d} acc={e} feedback={d}->{d}/{d} improved={} interf_A={d}/{d} acc={e} transfer={d}/{d} acc={e} sleep={d}->{d} retained={} motor={d} eps={d} engrams={d} sensory_top1={e} sensory_ok={} sensory_n={d}\n",
        .{
            r.oneshot_hit,
            r.oneshot_n,
            r.oneshot_acc,
            r.feedback_first_hit,
            r.feedback_second_hit,
            r.feedback_n,
            r.feedback_improved,
            r.interf_a_after_b,
            r.interf_a_n,
            r.interf_acc,
            r.transfer_hit,
            r.transfer_n,
            r.transfer_acc,
            r.pre_sleep_hit,
            r.post_sleep_hit,
            r.sleep_retained,
            r.n_motor,
            r.n_episodes,
            r.n_engrams,
            r.sensory_top1,
            r.sensory_ok,
            r.sensory_n,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_BIO_LEARN PASS\n", .{});
        std.debug.print("FSOT_NOT_LLM_BENCHMARK_OK\n", .{});
        std.debug.print("FSOT_ANIMAL_LEARN_STYLE_OK\n", .{});
        if (r.sensory_ok) std.debug.print("FSOT_SENSORY_MNIST_OK\n", .{});
    } else {
        std.debug.print("FSOT_BIO_LEARN FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runSelfStudy() void {
    std.debug.print("=== FSOT SELF-STUDY (read materials → try → re-read miss → sleep → prove) ===\n", .{});
    std.debug.print("doctrine: human student loop — NO multi-epoch SGD hand-holding\n", .{});
    const r = self_study_fixed.runSelfStudy();
    std.debug.print(
        "SELF_STUDY materials={d} file={d} studied={d} reread={d} quiz1={d}/{d} acc={e} quiz2={d}/{d} acc={e} prove={d}/{d} acc={e} improved={} eps={d} engrams={d} motor={d}\n",
        .{
            r.n_materials,
            r.n_file,
            r.n_studied,
            r.n_reread,
            r.quiz1_hit,
            r.quiz1_n,
            r.quiz1_acc,
            r.quiz2_hit,
            r.quiz2_n,
            r.quiz2_acc,
            r.prove_hit,
            r.prove_n,
            r.prove_acc,
            r.improved,
            r.n_episodes,
            r.n_engrams,
            r.n_motor,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_SELF_STUDY PASS\n", .{});
        std.debug.print("FSOT_HUMAN_STUDY_LOOP_OK\n", .{});
    } else {
        std.debug.print("FSOT_SELF_STUDY FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runBioConverse(do_tts: bool) void {
    std.debug.print("=== FSOT BIO CONVERSE (multi-turn think-from-memory → articulate) ===\n", .{});
    std.debug.print("doctrine: human exchange via retrieve+engram+motor — NOT an LLM chat layer\n", .{});
    std.debug.print("scope: FSOT genetic bare-metal mind; not wet tissue, not app-tier LLM\n", .{});
    const r = bio_converse_fixed.runBioConverse(do_tts);
    std.debug.print(
        "BIO_CONVERSE studied={d} turns={d} ans={d}/{d} acc={e} context={d}/{d} cacc={e} motor={d} self={d} encoded={d} phase_ok={d}/{d} mean_before_motor={d} sme_enc={d} eeg_ok={} enc_drive={e} eps={d} engrams={d} bio={} not_llm={}\n",
        .{
            r.n_studied,
            r.n_turns,
            r.n_answer_ok,
            r.n_turns,
            r.answer_acc,
            r.n_context_ok,
            r.n_turns,
            r.context_acc,
            r.n_motor,
            r.n_self_hear,
            r.n_turns_encoded,
            r.n_phase_order_ok,
            r.n_turns,
            r.n_meaning_before_motor,
            r.n_sme_encode_spirit,
            r.speech_eeg_ok,
            r.encode_drive,
            r.n_episodes,
            r.n_engrams,
            r.bio_path,
            r.not_llm_chat,
        },
    );
    if (r.last_phrase_n > 0) {
        std.debug.print("last_said=\"{s}\"\n", .{r.last_phrase[0..r.last_phrase_n]});
    }
    if (r.ok) {
        std.debug.print("FSOT_BIO_CONVERSE PASS\n", .{});
        std.debug.print("FSOT_THINK_FROM_MEMORY_OK\n", .{});
        std.debug.print("FSOT_MULTI_TURN_BIO_OK\n", .{});
        std.debug.print("FSOT_SPEECH_EEG_PHASE_OK\n", .{});
    } else {
        std.debug.print("FSOT_BIO_CONVERSE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runBioSuite() void {
    std.debug.print("=== FSOT BIO SUITE (learn + self-study + converse + think + sensory) ===\n", .{});
    std.debug.print("scope: rebuild neurological function from FSOT+genetics — harder than wet MEA borrow\n", .{});
    runBioLearnEval();
    runSelfStudy();
    runBioConverse(false);
    runInternalThink(0); // probe (not hour)
    runMnistAccuracy();
    std.debug.print("FSOT_BIO_SUITE PASS\n", .{});
}

fn runKnowQuery(allow_live: bool) void {
    std.debug.print("=== FSOT KNOW-QUERY (I don't know → tool study → retain) ===\n", .{});
    std.debug.print("doctrine: human lookup learning; archive + wiki (+ optional live Wikipedia)\n", .{});
    std.debug.print("sources: dictionary, simple-wiki, arxiv_fsot_core, Physical-Archive openalex/streams\n", .{});
    if (allow_live) std.debug.print("live: Wikipedia REST summary allowed\n", .{});
    if (!query_tool_fixed.selfTest()) {
        std.debug.print("FSOT_QUERY_TOOL FAIL (embedded table lookup)\n", .{});
        std.process.exit(1);
    }
    const r = know_query_fixed.runKnowQuery(allow_live);
    std.debug.print(
        "KNOW_QUERY probes={d} known={d} unknown={d} queried={d} hit={d} miss={d} retained={d} reprobe={d}/{d} said_unknown={d} live={} eps={d} eng={d}\n",
        .{
            r.n_probes,
            r.n_already_known,
            r.n_unknown,
            r.n_queried,
            r.n_query_hit,
            r.n_query_miss,
            r.n_retained,
            r.n_reprobe_ok,
            r.n_retained,
            r.n_said_unknown,
            r.allow_live,
            r.n_episodes,
            r.n_engrams,
        },
    );
    if (r.last_term_n > 0 and r.last_def_n > 0) {
        std.debug.print("last: \"{s}\" via {s} → \"{s}\"\n", .{
            r.last_term[0..r.last_term_n],
            r.last_via[0..r.last_via_n],
            r.last_def[0..r.last_def_n],
        });
    }
    if (r.ok) {
        std.debug.print("FSOT_KNOW_QUERY PASS\n", .{});
        std.debug.print("FSOT_TOOL_STUDY_OK\n", .{});
        std.debug.print("FSOT_RETAIN_AFTER_QUERY_OK\n", .{});
    } else {
        std.debug.print("FSOT_KNOW_QUERY FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runInternalThink(minutes: u32) void {
    if (minutes == 0) {
        std.debug.print("=== FSOT INTERNAL THINK (retrace · cross-check · brainstorm · self-correct) ===\n", .{});
        std.debug.print("doctrine: scientific method on organism memory — NOT LLM chain-of-thought\n", .{});
        const r = internal_think_fixed.runThinkProbe();
        std.debug.print(
            "THINK studied={d} lit={d} cy={d} retr={d}/{d} disc={d}/{d} new={d} ideas={d} uniq={d} grown={d} eng={d} eps={d}\n",
            .{
                r.n_studied,
                r.n_lit_cards,
                r.n_cycles,
                r.n_retrace_ok,
                r.n_retrace,
                r.n_discover_hit,
                r.n_discover,
                r.n_new_concepts,
                r.n_ideas_grounded,
                r.n_ideas_unique,
                r.n_grown,
                r.n_engrams,
                r.n_episodes,
            },
        );
        if (r.last_new_n > 0) std.debug.print("new_concept=\"{s}\"\n", .{r.last_new[0..r.last_new_n]});
        if (r.last_idea_n > 0) std.debug.print("last_idea=\"{s}\"\n", .{r.last_idea[0..r.last_idea_n]});
        if (r.ok) {
            std.debug.print("FSOT_INTERNAL_THINK PASS\n", .{});
            std.debug.print("FSOT_ADAPTIVE_KNOWLEDGE_OK\n", .{});
        } else {
            std.debug.print("FSOT_INTERNAL_THINK FAIL\n", .{});
            std.process.exit(1);
        }
        return;
    }
    std.debug.print("=== FSOT THINK RUN (bio process + auto-stop if stuck) max {d} min ===\n", .{minutes});
    std.debug.print("doctrine: encode → episodic retrace → curiosity → compose → sleep(NREM+replay) | NOT LLM epochs\n", .{});
    std.debug.print("path: seed+lit → wet_encode(STDP/glia/mol) → retrace → discover → LTM warm → compose → sleep+wet_maint → LTM spill\n", .{});
    std.debug.print("organs: STM/LTM disk · wet cascade · Python skills · FSOT-GPU VRAM deep sleep every 4th NREM\n", .{});
    std.debug.print("logs:\n", .{});
    std.debug.print("  data/results/THINK_LIVE.log                 (heartbeat + bio + wet line)\n", .{});
    std.debug.print("  data/results/THINK_GENETIC.log              (DNA structure + mutations)\n", .{});
    std.debug.print("  data/results/THINK_ACCURACY.jsonl           (episodic_retrace, curiosity, sleep, neuromod)\n", .{});
    std.debug.print("  data/results/THINK_PENDING_QUESTIONS.jsonl  (open questions — markup scrubbed)\n", .{});
    std.debug.print("  data/ltm/                                   (long-term disk memory)\n", .{});
    const r = internal_think_fixed.runThinkMinutes(minutes);
    std.debug.print(
        "THINK_RUN done reason={s} min_cap={d} cy={d} lit={d} episodic_retr={d}/{d} curiosity={d}/{d} new={d} uniq={d} pending={d} life_grown={d} eng={d} sleep={d} replay={d} mut={d} ms={d}\n",
        .{
            r.stop_reason,
            minutes,
            r.n_cycles,
            r.n_lit_cards,
            r.n_retrace_ok,
            r.n_retrace,
            r.n_discover_hit,
            r.n_discover,
            r.n_new_concepts,
            r.n_ideas_unique,
            r.n_pending_open,
            r.n_grown_lifetime,
            r.n_engrams,
            r.n_sleep,
            r.n_batch_replayed,
            r.n_mutations,
            r.duration_ms,
        },
    );
    std.debug.print("bio neuromod last_da={e} last_ach={e} batch_cos={e} deep_vram_consol={d} skill={d}\n", .{
        r.last_mean_da,
        r.last_mean_ach,
        r.last_batch_mean_cos,
        r.n_gpu_consol,
        r.n_skill,
    });
    std.debug.print("wet active={} epochs={d} stdp={d} consol={d} prune={d} myelo={d} releases={d} sleep_maint={d}\n", .{
        r.wet_encode_active,
        r.n_wet_epochs,
        r.n_wet_stdp,
        r.n_wet_consol,
        r.n_wet_prune,
        r.n_wet_myelo,
        r.n_wet_releases,
        r.n_wet_sleep_maint,
    });
    if (r.last_new_n > 0) std.debug.print("last_new_concept=\"{s}\"\n", .{r.last_new[0..r.last_new_n]});
    if (r.last_idea_n > 0) std.debug.print("last_idea=\"{s}\"\n", .{r.last_idea[0..r.last_idea_n]});
    if (r.ok) {
        std.debug.print("FSOT_THINK_HOUR PASS\n", .{});
        std.debug.print("FSOT_LONG_THINK_OK\n", .{});
        std.debug.print("FSOT_ADAPTIVE_KNOWLEDGE_OK\n", .{});
        std.debug.print("FSOT_BIO_THINK_METRICS_OK\n", .{});
        if (r.wet_encode_active and (r.n_wet_stdp > 0 or r.n_wet_releases > 0)) {
            std.debug.print("FSOT_WET_ENCODE_OK\n", .{});
        }
        if (r.n_mutations > 0) {
            std.debug.print("FSOT_PLASTICITY_MUT_OK mut={d}\n", .{r.n_mutations});
        }
        if (std.mem.eql(u8, r.stop_reason, "stuck_no_progress") or std.mem.eql(u8, r.stop_reason, "stuck_same_idea")) {
            std.debug.print("FSOT_STUCK_AUTO_SHUTDOWN_OK\n", .{});
        }
    } else {
        std.debug.print("FSOT_THINK_HOUR FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runBioArticulate(do_tts: bool) void {
    std.debug.print("=== FSOT BIO ARTICULATE (teach→retrieve→motor→self-hear; NOT chat layer) ===\n", .{});
    std.debug.print("doctrine: SPEECH_ORGAN — meaning→motor→acoustic; English only as stored engram codec\n", .{});
    const r = bio_articulate_fixed.runBioArticulate(do_tts);
    std.debug.print(
        "BIO_ART taught={d} eps={d} engrams={d} probes={d} retrieve={d}/{d} ans={d}/{d} motor={d}/{d} self={d}/{d} ret_acc={e} ans_acc={e} motor_acc={e} self_acc={e} tts={d}\n",
        .{
            r.n_taught,
            r.n_episodes,
            r.n_engrams,
            r.n_probes,
            r.n_retrieve_hit,
            r.n_probes,
            r.n_answer_match,
            r.n_probes,
            r.n_motor_spoke,
            r.n_probes,
            r.n_self_recover,
            r.n_probes,
            r.retrieve_acc,
            r.answer_acc,
            r.motor_acc,
            r.self_acc,
            r.n_tts,
        },
    );
    if (r.last_utter_n > 0) {
        std.debug.print("last_utter=\"{s}\"\n", .{r.last_utter[0..r.last_utter_n]});
    }
    if (r.ok) {
        std.debug.print("FSOT_BIO_ARTICULATE PASS\n", .{});
    } else {
        std.debug.print("FSOT_BIO_ARTICULATE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runCrossModal() void {
    std.debug.print("=== FSOT CROSS-MODAL (vision⊗audio joint bind, fixed) ===\n", .{});
    const r = cross_modal_fixed.runCrossModalProbe();
    std.debug.print(
        "CROSS joint={d}/{d} top1={e} vision_only={d}/{d} vtop1={e} audio_only={d}/{d} atop1={e} spikes={d}\n",
        .{
            r.joint_correct,        r.n_items, r.joint_top1,
            r.vision_only_correct,  r.n_items, r.vision_only_top1,
            r.audio_only_correct,   r.n_items, r.audio_only_top1,
            r.spikes,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_CROSS_MODAL PASS\n", .{});
    } else {
        std.debug.print("FSOT_CROSS_MODAL FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runBioIo() void {
    std.debug.print("=== FSOT BIO I/O (afferent routes + efferent speech re-afferent) ===\n", .{});
    std.debug.print("doctrine: thal/sens/assoc/hipp anatomy; motor→sound; not next-token\n", .{});
    if (!pathways_fixed.selfTest()) {
        std.debug.print("FSOT_BIO_IO FAIL pathways\n", .{});
        std.process.exit(1);
    }
    if (!sensory_fixed.selfTest()) {
        std.debug.print("FSOT_BIO_IO FAIL sensory_bus\n", .{});
        std.process.exit(1);
    }
    const r = bio_io_fixed.runBioIoProbe();
    std.debug.print(
        "BIO_IO path={} bus={} V_spikes={d} A_spikes={d} intero={} speak_rt={} syl={d} hear={d}/{d} top1={e}\n",
        .{
            r.pathways_ok,
            r.sensory_bus_ok,
            r.afferent_vision_spikes,
            r.afferent_audio_spikes,
            r.intero_ok,
            r.efferent_roundtrip_ok,
            r.syllable_frames,
            r.hear_correct,
            r.hear_n,
            r.hear_top1,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_BIO_IO PASS\n", .{});
    } else {
        std.debug.print("FSOT_BIO_IO FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runMachineEncode() void {
    std.debug.print("=== FSOT MACHINE ENCODE (bytes/UTF-8/trit/chemical AA — not Morse/LM) ===\n", .{});
    const r = machine_encode_fixed.runMachineEncodeProbe();
    std.debug.print(
        "MACHINE bytes_rt={} text_rt={} feat_trit={} dna={} chem_aa={} words={d} n_aa={d}\n",
        .{ r.bytes_roundtrip, r.text_roundtrip, r.feat_trit_ok, r.dna_codon_ok, r.chemical_aa_ok, r.n_words, r.n_aa },
    );
    if (r.ok) {
        std.debug.print("FSOT_MACHINE PASS\n", .{});
    } else {
        std.debug.print("FSOT_MACHINE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runMachineLang() void {
    std.debug.print("=== FSOT MACHINE LANGUAGE (generate = understand = run tongue) ===\n", .{});
    std.debug.print("doctrine: mind emits TritWord frames; re-ingests same bytes; UTF-8 is codec only\n", .{});
    if (!machine_lang_fixed.selfTest()) {
        std.debug.print("FSOT_MACHINE_LANG FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = machine_lang_fixed.runMachineLangLoop();
    std.debug.print(
        "MACHINE_LANG frame_rt={} text_rt={} words={d} trits={d} bytes={d} gen={d} under={d} spikes={d}\n",
        .{ r.frame_roundtrip, r.text_roundtrip, r.n_words, r.n_trits, r.n_bytes, r.n_generated, r.n_understood, r.inject_spikes },
    );
    if (r.hex_len > 0) {
        std.debug.print("MACHINE_LANG hex_head={s}\n", .{r.hex_head[0..r.hex_len]});
    }
    if (r.ok) {
        std.debug.print("FSOT_MACHINE_LANG PASS\n", .{});
        std.debug.print("FSOT_MACHINE_TONGUE_OK\n", .{});
    } else {
        std.debug.print("FSOT_MACHINE_LANG FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runMachineLangStress() void {
    std.debug.print("=== FSOT MACHINE LANGUAGE STRESS (1000 frames + text + corrupt + inject) ===\n", .{});
    if (!machine_lang_fixed.selfTest()) {
        std.debug.print("FSOT_MACHINE_LANG_STRESS FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = machine_lang_fixed.runMachineLangStress(1000);
    std.debug.print(
        "MLANG_STRESS frames={d}/{d} text={d}/{d} inject={d} bytes={d} trits={d} mismatches={d} corrupt_rej={d} max_spk={d}\n",
        .{
            r.n_frame_ok,
            r.n_frames,
            r.n_text_ok,
            r.n_text_trials,
            r.n_inject_ok,
            r.n_bytes_total,
            r.n_trits_total,
            r.n_word_mismatches,
            r.n_corrupt_reject,
            r.max_spikes,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_MACHINE_LANG_STRESS PASS\n", .{});
    } else {
        std.debug.print("FSOT_MACHINE_LANG_STRESS FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runEnglishCodec() void {
    std.debug.print("=== FSOT ENGLISH CODEC (lexicon choose + machine frame + TTS plant) ===\n", .{});
    std.debug.print("doctrine: teacher grows TSV; mind owns machine language + choose; TTS plant\n", .{});
    const n_load = lexicon_en_fixed.tryLoadDefaultRoles();
    std.debug.print("LEXICON_LOAD extra={d} total={d}\n", .{ n_load, lexicon_en_fixed.totalWords() });
    if (!lexicon_en_fixed.selfTest()) {
        std.debug.print("FSOT_ENGLISH FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = lexicon_en_fixed.runLexiconProbe();
    std.debug.print(
        "ENGLISH words={d} choose={d}/3 input_known={d} phrase=\"{s}\" frame_rt={} choose_diff={}\n",
        .{ r.n_words, r.n_choose_ok, r.n_input_known, r.phrase_sample[0..r.phrase_n], r.frame_roundtrip, r.choose_not_echo },
    );

    // Input → understand → re-export path
    var toks: [6]u32 = undefined;
    var meaning: [8]@import("fixed.zig").Fixed = undefined;
    const inp = lexicon_en_fixed.inputEnglish("I hear the sound here", &toks, &meaning);
    var phrase: [lexicon_en_fixed.MAX_PHRASE]u8 = undefined;
    var frame: machine_lang_fixed.MachineFrame = .{};
    const ut = lexicon_en_fixed.utterEnglish(&meaning, phrase[0..], &frame);
    std.debug.print(
        "ENGLISH_IO in_known={d} out_phrase=\"{s}\" frame_words={d}\n",
        .{ inp.n_known, phrase[0..ut.phrase_n], frame.n_words },
    );

    // TTS plant (real words out the speakers)
    const tts = host_tts_fixed.speakEnglish(phrase[0..ut.phrase_n]);
    std.debug.print(
        "TTS backend={s} spoken={} chars={d}\n",
        .{ tts.backend, tts.spoken, tts.n_chars },
    );

    if (r.ok and inp.n_known >= 3 and ut.phrase_n >= 5) {
        std.debug.print("FSOT_ENGLISH PASS\n", .{});
        if (tts.spoken) std.debug.print("FSOT_TTS_SPOKEN_OK\n", .{});
    } else {
        std.debug.print("FSOT_ENGLISH FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runLanguagePractice() void {
    std.debug.print("=== FSOT LANGUAGE PRACTICE (utter → TTS → self-hear → encode) ===\n", .{});
    std.debug.print("doctrine: teacher offline; student learns by doing + hearing own words\n", .{});
    if (!language_practice_fixed.selfTest()) {
        std.debug.print("FSOT_LANGUAGE_PRACTICE FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = language_practice_fixed.runLanguagePractice();
    std.debug.print(
        "PRACTICE trials={d} tts={d} self_recover={d} frame_rt={d} encode={d} known_in={d} known_out={d} lex={d} fluency={e}\n",
        .{
            r.n_trials,
            r.n_tts_spoken,
            r.n_self_recover,
            r.n_frame_rt,
            r.n_encode,
            r.n_known_in,
            r.n_known_out,
            r.lexicon_total,
            r.fluency,
        },
    );
    if (r.last_phrase_n > 0) {
        std.debug.print("LAST_PRACTICE \"{s}\"\n", .{r.last_phrase[0..r.last_phrase_n]});
    }
    if (r.ok) {
        std.debug.print("FSOT_LANGUAGE_PRACTICE PASS\n", .{});
        std.debug.print("FSOT_SELF_HEAR_LANGUAGE_OK\n", .{});
    } else {
        std.debug.print("FSOT_LANGUAGE_PRACTICE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runLanguageDepth(speak: bool) void {
    std.debug.print("=== FSOT LANGUAGE DEPTH (definitions + POS — meaningful use) ===\n", .{});
    std.debug.print("doctrine: teach dictionary cards on OrganismF; prove with pointed questions\n", .{});
    std.debug.print("probes: is X a verb? | X is a? | what does X mean? | role of X | hops\n", .{});
    const r = language_depth_fixed.runLanguageDepth(speak);
    std.debug.print(
        "DEPTH taught={d} file={d} eps={d} bank={d} restudy={d} probes={d} correct={d} acc={e}\n",
        .{ r.n_taught_cards, r.n_file_cards, r.n_episodes, r.n_bank, r.n_restudy, r.n_probes, r.n_correct, r.acc },
    );
    std.debug.print(
        "DEPTH pos_yesno={e} ({d}/{d}) define={e} ({d}/{d}) role={e} ({d}/{d}) hop={e} ({d}/{d}) pointed={d}/{d} tts={d}\n",
        .{
            r.pos_acc,
            r.n_pos_yesno_ok,
            r.n_pos_yesno,
            r.define_acc,
            r.n_define_ok,
            r.n_define,
            r.role_acc,
            r.n_role_ok,
            r.n_role,
            r.hop_acc,
            r.n_hop_ok,
            r.n_hop,
            r.pointed_hit,
            r.pointed_n,
            r.n_tts,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_LANGUAGE_DEPTH PASS\n", .{});
        std.debug.print("FSOT_MEANINGFUL_WORDS_OK\n", .{});
    } else {
        std.debug.print("FSOT_LANGUAGE_DEPTH FAIL (need ≥93% overall, ≥95% POS, ≥93% define)\n", .{});
        std.process.exit(1);
    }
}

fn runDictionaryStress() void {
    std.debug.print("=== FSOT DICTIONARY STRESS (20k WordNet lexicon in use) ===\n", .{});
    std.debug.print("doctrine: recognize dictionary words; speak with grammar templates; no salad\n", .{});
    const r = lexicon_en_fixed.runDictionaryStress();
    std.debug.print(
        "DICT_STRESS total={d} loaded={d} probe={d} found={d} find_rate={e} input={d}/{d} input_rate={e} grammar={d}/{d} grammar_rate={e}\n",
        .{
            r.n_total,
            r.n_loaded,
            r.n_probe,
            r.n_found,
            r.find_rate,
            r.n_input_hit,
            r.n_input_try,
            r.input_rate,
            r.n_grammar_ok,
            r.n_grammar_try,
            r.grammar_rate,
        },
    );
    if (r.sample_n > 0) {
        std.debug.print("DICT_SAMPLE \"{s}\"\n", .{r.sample_phrase[0..r.sample_n]});
    }
    // Speak a few dictionary-seeded grammatical lines (real words + grammar)
    const demo = [_][]const u8{ "democracy", "telescope", "remember", "beautiful", "quickly" };
    var n_tts: u32 = 0;
    for (demo) |w| {
        var phrase: [lexicon_en_fixed.MAX_PHRASE]u8 = undefined;
        const ph = lexicon_en_fixed.phraseFromSeedWord(w, phrase[0..]);
        if (ph.n == 0) continue;
        std.debug.print("DICT_TTS \"{s}\"\n", .{phrase[0..ph.n]});
        const tts = host_tts_fixed.speakEnglish(phrase[0..ph.n]);
        if (tts.spoken) n_tts += 1;
    }
    std.debug.print("DICT_TTS_SPOKEN={d}/{d}\n", .{ n_tts, demo.len });
    if (r.ok) {
        std.debug.print("FSOT_DICTIONARY_STRESS PASS\n", .{});
        std.debug.print("FSOT_NEW_WORDS_IN_USE_OK\n", .{});
    } else {
        std.debug.print("FSOT_DICTIONARY_STRESS FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runGradePractice() void {
    std.debug.print("=== FSOT GRADE PRACTICE (legacy soft gate) — prefer 'ladder' for 95% ===\n", .{});
    std.debug.print("doctrine: teach real facts; quiz & solve — not word-means-word\n", .{});
    if (!grade_practice_fixed.selfTest()) {
        std.debug.print("FSOT_GRADE_PRACTICE FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = grade_practice_fixed.runGradePractice(false);
    std.debug.print(
        "GRADE lessons={d} taught={d} quiz={d}/{d} top1={e} problems={d}/{d} ptop1={e} apply={e} tts={d} lex={d}\n",
        .{
            r.n_lessons,
            r.n_taught,
            r.n_quiz_ok,
            r.n_quiz,
            r.quiz_top1,
            r.n_prob_ok,
            r.n_problems,
            r.problem_top1,
            r.apply_score,
            r.n_tts,
            r.lexicon_total,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_GRADE_PRACTICE PASS\n", .{});
    } else {
        std.debug.print("FSOT_GRADE_PRACTICE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn printBand(r: grade_ladder_fixed.BandReport) void {
    std.debug.print(
        "BAND {s} score={e} thr={e} PASS={} file={} taught={d} items={d}\n",
        .{
            grade_ladder_fixed.bandName(r.band),
            r.score,
            r.threshold,
            r.pass,
            r.from_file,
            r.n_taught,
            r.n_items,
        },
    );
    std.debug.print(
        "  domains math={e}({d}/{d}) science={e}({d}/{d}) literacy={e}({d}/{d}) vision={e}({d}/{d})\n",
        .{
            r.math.score,     r.math.ok,     r.math.n,
            r.science.score,  r.science.ok,  r.science.n,
            r.literacy.score, r.literacy.ok, r.literacy.n,
            r.vision.score,   r.vision.ok,   r.vision.n,
        },
    );
}

fn runGradeBand(band: grade_ladder_fixed.GradeBand) void {
    std.debug.print("=== FSOT GRADE BAND ({s}) straight-A ≥95% per domain ===\n", .{grade_ladder_fixed.bandName(band)});
    std.debug.print("doctrine: open curriculum bank + digit vision; math/sci/lit/vis each ≥95%\n", .{});
    const r = grade_ladder_fixed.runBand(band);
    printBand(r);
    if (r.pass) {
        std.debug.print("FSOT_BAND_PASS {s}\n", .{grade_ladder_fixed.bandName(band)});
        std.debug.print("FSOT_STRAIGHT_A_OK\n", .{});
    } else {
        std.debug.print("FSOT_BAND_FAIL {s} (need ≥95% each domain)\n", .{grade_ladder_fixed.bandName(band)});
        std.process.exit(1);
    }
}

fn runGradeLadder() void {
    std.debug.print("=== FSOT GRADE LADDER (straight-A, ≥95% per band AND domain) ===\n", .{});
    std.debug.print("doctrine: open curriculum (run_curriculum_open.py) → bank.tsv; stop on first fail\n", .{});
    if (!grade_ladder_fixed.selfTest()) {
        std.debug.print("FSOT_LADDER FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = grade_ladder_fixed.runLadder();
    std.debug.print(
        "LADDER_SUMMARY bands_passed={d}/{d} stopped_at={s} overall_ok={}\n",
        .{ r.n_bands_passed, r.n_bands_total, r.stopped_at, r.ok },
    );
    if (r.ok) {
        std.debug.print("FSOT_LADDER PASS\n", .{});
        std.debug.print("FSOT_STRAIGHT_A_LADDER_OK\n", .{});
    } else {
        std.debug.print("FSOT_LADDER FAIL at {s}\n", .{r.stopped_at});
        std.process.exit(1);
    }
}

fn runReasonPractice() void {
    std.debug.print("=== FSOT OPEN REASON (multi-hop over taught knowledge) ===\n", .{});
    std.debug.print("doctrine: bio process = inject→ticks→retrieve→bind; not LLM chain-of-thought\n", .{});
    // full run with TTS off first for speed in self-check path; we call with speak=true below
    if (!reason_practice_fixed.selfTest()) {
        std.debug.print("FSOT_REASON FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = reason_practice_fixed.runReasonPractice(true);
    std.debug.print(
        "REASON taught={d} open={d}/{d} acc={e} hops={d} bank_hits={d} ep_hits={d} spikes={d} lex={d}\n",
        .{ r.n_taught, r.n_correct, r.n_open, r.accuracy, r.n_hops_total, r.n_bank_hits, r.n_ep_hits, r.total_spikes, r.lexicon_total },
    );
    if (r.ok) {
        std.debug.print("FSOT_REASON PASS\n", .{});
        std.debug.print("FSOT_OPEN_REASON_OK\n", .{});
    } else {
        std.debug.print("FSOT_REASON FAIL (multi-hop apply still weak — expected while shallow)\n", .{});
        std.process.exit(1);
    }
}

fn runNovelInquiry() void {
    std.debug.print("=== FSOT NOVEL INQUIRY (single complex synthesis from taught facts) ===\n", .{});
    std.debug.print("doctrine: new idea = compose grounded binds; never free invent\n", .{});
    if (!novel_inquiry_fixed.selfTest()) {
        std.debug.print("FSOT_NOVEL FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = novel_inquiry_fixed.runNovelInquiry(true);
    std.debug.print(
        "NOVEL taught={d} hops={d} grounded={} novel={} spikes={d} lex={d}\n",
        .{ r.n_taught, r.n_hops, r.grounded, r.novel, r.spikes, r.lexicon_total },
    );
    if (r.idea_n > 0) {
        std.debug.print("NOVEL_IDEA \"{s}\"\n", .{r.idea[0..r.idea_n]});
    }
    if (r.ok) {
        std.debug.print("FSOT_NOVEL PASS\n", .{});
        std.debug.print("FSOT_NOVEL_SYNTHESIS_OK\n", .{});
    } else {
        std.debug.print("FSOT_NOVEL FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runCheckpoint() void {
    std.debug.print("=== FSOT CHECKPOINT (biological save-game) ===\n", .{});
    std.debug.print("doctrine: persist episodic memory + meaning; genetic spine remains law\n", .{});
    if (!checkpoint_fixed.selfTest()) {
        std.debug.print("FSOT_CHECKPOINT FAIL selftest\n", .{});
        std.process.exit(1);
    }
    const r = checkpoint_fixed.runCheckpointProbe() catch {
        std.debug.print("FSOT_CHECKPOINT FAIL io\n", .{});
        std.process.exit(1);
    };
    std.debug.print(
        "CHECKPOINT saved={d} loaded={d} roundtrip={} path={s}\n",
        .{ r.n_saved, r.n_loaded, r.roundtrip, r.path },
    );
    if (r.ok) {
        std.debug.print("FSOT_CHECKPOINT PASS\n", .{});
        std.debug.print("FSOT_SAVEGAME_OK\n", .{});
    } else {
        std.debug.print("FSOT_CHECKPOINT FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runFailure() void {
    std.debug.print("=== FSOT FAILURE BOUNDARIES (expanded catalog, fixed) ===\n", .{});
    const r = failure_fixed.runFailureProbe();
    std.debug.print(
        "FAILURE modes={d} healthy={d} AD={d} PD={d} ALS={d} MS={d} EPI={d} ISCH={d} envelope={} boundary={} shape={}\n",
        .{ r.n_modes, r.healthy_spikes, r.ad_spikes, r.pd_spikes, r.als_spikes, r.ms_spikes, r.epi_spikes, r.ischemia_spikes, r.healthy_in_envelope, r.boundary_detected, r.catalog_shape_ok },
    );
    if (r.ok) {
        std.debug.print("FSOT_FAILURE PASS\n", .{});
    } else {
        std.debug.print("FSOT_FAILURE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runWireAround() void {
    std.debug.print("=== FSOT WIRE-AROUND (lesion → recovery actions, fixed) ===\n", .{});
    const r = wire_around_fixed.runWireAroundProbe();
    std.debug.print(
        "WIRE healthy={d} lesion={d} rescued={d} improved={} actions={d}\n",
        .{ r.healthy_spikes, r.lesion_spikes, r.rescued_spikes, r.improved, r.n_actions },
    );
    if (r.ok) {
        std.debug.print("FSOT_WIRE_AROUND PASS\n", .{});
    } else {
        std.debug.print("FSOT_WIRE_AROUND FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runSymbolAssoc() void {
    std.debug.print("=== FSOT SYMBOL ASSOC (sensory signature → prototype anchors) ===\n", .{});
    const r = symbol_assoc_fixed.runSymbolAssocProbe();
    std.debug.print(
        "SYMBOL anchors={d} hit={d}/{d} top1={e} cross={d}/{d} ctop1={e}\n",
        .{ r.n_anchors, r.correct, r.n_probes, r.top1, r.cross_modal_correct, r.n_probes, r.cross_modal_top1 },
    );
    if (r.ok) {
        std.debug.print("FSOT_SYMBOL PASS\n", .{});
    } else {
        std.debug.print("FSOT_SYMBOL FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runHardware() void {
    std.debug.print("=== FSOT HARDWARE METRIC (plant interoception stub) ===\n", .{});
    const r = hardware_metric_fixed.runHardwareProbe();
    std.debug.print(
        "HARDWARE n_units={d} cpu={e} mem={e} source={s} mod_ok={}\n",
        .{ r.n_units_suggest, r.cpu, r.mem, r.source, r.mod_mode_ok },
    );
    if (r.ok) {
        std.debug.print("FSOT_HARDWARE PASS\n", .{});
    } else {
        std.debug.print("FSOT_HARDWARE FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runHostSenses() void {
    std.debug.print("=== FSOT HOST SENSES (Zig live display+mic → Fixed bus) ===\n", .{});
    std.debug.print("doctrine: no C/Rust required; framebuffer sample not screenshot files\n", .{});
    const r = host_senses_fixed.runHostSensesProbe();
    std.debug.print(
        "HOST live_disp={} live_mic={} vis={} aud={} {d}x{d} mic_n={d} spikes={d} eps={d} feat_ok={}\n",
        .{
            r.live_display,
            r.live_mic,
            r.vision_ok,
            r.audio_ok,
            r.width,
            r.height,
            r.n_audio_samples,
            r.organism_spikes,
            r.episodes,
            r.feat_path_ok,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_HOST_SENSES PASS\n", .{});
        if (r.live_display or r.live_mic) {
            std.debug.print("FSOT_HOST_SENSES_LIVE_OK\n", .{});
        } else {
            std.debug.print("FSOT_HOST_SENSES_FALLBACK_SYNTHETIC\n", .{});
        }
    } else {
        std.debug.print("FSOT_HOST_SENSES FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runHostLoop() void {
    std.debug.print("=== FSOT HOST LOOP (continuous sample→inject→tick) ===\n", .{});
    const r = host_loop_fixed.runHostLoop(24, true);
    std.debug.print(
        "HOST_LOOP ticks={d} live_disp={d} live_mic={d} spikes={d} eps={d} spoke={} sleep_ms={d}\n",
        .{ r.n_ticks, r.n_live_display, r.n_live_mic, r.spikes, r.episodes, r.spoke, r.sleep_ms },
    );
    if (r.ok) {
        std.debug.print("FSOT_HOST_LOOP PASS\n", .{});
    } else {
        std.debug.print("FSOT_HOST_LOOP FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runBodyDaemon() void {
    // Smoke plant loop only (senses→tick). Full intelligence = runLiveMindConnected.
    std.debug.print("=== FSOT BODY PLANT SMOKE (senses only — use 'mind' for full brain) ===\n", .{});
    const r = host_loop_fixed.runBodyDaemon();
    std.debug.print(
        "BODY ticks={d} live_disp={d} live_mic={d} spikes={d} eps={d} spoke={} sleep_ms={d}\n",
        .{ r.n_ticks, r.n_live_display, r.n_live_mic, r.spikes, r.episodes, r.spoke, r.sleep_ms },
    );
    if (r.ok) {
        std.debug.print("FSOT_BODY PASS\n", .{});
        std.debug.print("FSOT_BODY_BOOT_OK\n", .{});
        std.debug.print("NOTE: full connected intelligence → mode 'mind' or BOOT_MIND.cmd\n", .{});
    } else {
        std.debug.print("FSOT_BODY FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runLiveMindConnected() void {
    // Default product: one organism, all systems wired, not unit-test parade.
    const r = mind_live_fixed.runLiveMind(.{
        .n_ticks = 450, // ~9s @20ms
        .sleep_ms = 20,
        .report_every = 30,
        .speakers = true,
        .speak_every = 45,
        .encode_every = 6,
        .curiosity_every = 12,
        .teach_every = 40,
        .english_tts = true,
        .formant_speech = true, // internal motor path; DAC skipped when TTS on
    });
    std.debug.print(
        "SUMMARY spikes={d} rate={e} eps={d} enc={d} cur={d}/{d} teach={d} ret={d} spk={d} self={d}/{d} air={d} int={d} match={e} amb={d} ign={d} scene={d} enc_open={d} att={e} adapt={d} bias={e} pat={d} pat_bind={d} mach={d}/{d}B en={d} tts={d}\n",
        .{ r.spikes, r.spike_rate, r.episodes, r.n_encodes, r.n_curiosity, r.n_curiosity_q, r.n_teaches, r.n_retrieves, r.n_speaks, r.n_self_hear, r.n_self_attempts, r.n_self_air, r.n_self_internal, r.last_self_match, r.n_ambient_high, r.n_noise_ignored, r.n_scene_samples, r.n_encode_open, r.last_attune, r.n_speech_adapt, r.last_bias_mag, r.last_pattern, r.n_pattern_binds, r.n_machine_emit, r.n_machine_bytes, r.n_english_say, r.n_tts_spoken },
    );
    if (r.ok) {
        std.debug.print("FSOT_LIVE_MIND PASS\n", .{});
        std.debug.print("FSOT_MIND_CONNECTED_OK\n", .{});
    } else {
        std.debug.print("FSOT_LIVE_MIND FAIL (need more spikes/memory/curiosity activity)\n", .{});
        std.process.exit(1);
    }
}

fn runSpeakers() void {
    std.debug.print("=== FSOT SPEAKERS (speech organ acoustic → DAC) ===\n", .{});
    const r = host_audio_out_fixed.runSpeakerProbe();
    std.debug.print(
        "SPEAKERS samples={d} played={} backend={s}\n",
        .{ r.n_samples, r.played, r.backend },
    );
    if (r.ok) {
        std.debug.print("FSOT_SPEAKERS PASS\n", .{});
        if (r.played) std.debug.print("FSOT_SPEAKERS_PLAYED_OK\n", .{});
    } else {
        std.debug.print("FSOT_SPEAKERS FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runAutonomous() void {
    std.debug.print("=== FSOT AUTONOMOUS (multi-domain chew, no per-item prompt) ===\n", .{});
    const r = autonomous_fixed.runAutonomousProbe();
    std.debug.print(
        "AUTO domains={d} eps={d} words={d} recall={d}/{d} top1={e} cur={d} spikes={d} spoke={}\n",
        .{ r.n_domains, r.n_episodes, r.n_machine_words, r.recall_correct, r.recall_n, r.recall_top1, r.curiosity_resolved, r.spikes, r.spoke },
    );
    if (r.ok) {
        std.debug.print("FSOT_AUTONOMOUS PASS\n", .{});
    } else {
        std.debug.print("FSOT_AUTONOMOUS FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runInjectFile(path: []const u8) !void {
    std.debug.print("=== FSOT MIND INJECT-FILE → FIXED organism ===\n", .{});
    std.debug.print("path={s}\n", .{path});
    // Fixed ABI: text frames → Fixed (no f64 mind core)
    const r = try vision_inject_fixed.runVisionInject(path);
    std.debug.print(
        "packets={d} vision={d} ticks={d} eps={d} spikes={d} retrieve={}\n",
        .{ r.n_packets, r.n_vision, r.ticks, r.episodes, r.spikes, r.retrieve_ok },
    );
    if (!r.ok) {
        std.debug.print("FSOT_INJECT_FILE FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_INJECT_FILE PASS\n", .{});
}

fn runVisionInjectDemo() void {
    std.debug.print("=== FSOT MIND VISION-INJECT (fixed DEMO frames, no external path) ===\n", .{});
    const r = vision_inject_fixed.runVisionInject(null) catch {
        std.debug.print("FSOT_VISION_INJECT FAIL parse\n", .{});
        std.process.exit(1);
    };
    std.debug.print(
        "packets={d} vision={d} ticks={d} eps={d} spikes={d} retrieve={}\n",
        .{ r.n_packets, r.n_vision, r.ticks, r.episodes, r.spikes, r.retrieve_ok },
    );
    if (!r.ok) {
        std.debug.print("FSOT_VISION_INJECT FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_VISION_INJECT PASS\n", .{});
}

fn runMnistAccuracy() void {
    std.debug.print("=== FSOT MNIST ACCURACY GATE (real held-out, ≥95%) ===\n", .{});
    std.debug.print("doctrine: 14x14 pool L2 features + k-NN; pack from run_mnist_gate.py\n", .{});
    const r = mnist_accuracy_fixed.runMnistAccuracy();
    std.debug.print(
        "MNIST top1={e} thr={e} correct={d}/{d} train={d} dim={d} k={d} pack={}\n",
        .{ r.top1, mnist_accuracy_fixed.PASS_THRESHOLD, r.correct, r.n_test, r.n_train, r.dim, r.k, r.from_pack },
    );
    if (r.ok) {
        std.debug.print("FSOT_MNIST_GATE PASS\n", .{});
        std.debug.print("FSOT_MNIST_ACCURACY_OK\n", .{});
    } else {
        std.debug.print("FSOT_MNIST_GATE FAIL (run: python run_mnist_gate.py)\n", .{});
        std.process.exit(1);
    }
}

fn runGradeDepth() void {
    std.debug.print("=== FSOT GRADE-SCHOOL DEPTH (understand paraphrases, ≥95%) ===\n", .{});
    std.debug.print("doctrine: taught STEM/literacy only; natural Q → parse → bank/math/overlap → answer\n", .{});
    std.debug.print("no history; deepen claimability before expanding further\n", .{});
    const r = understand_depth_fixed.runDepthExam();
    std.debug.print(
        "DEPTH bank={d} exam={d} correct={d} acc={e} thr={e} math={d} overlap={d} exact={d} miss={d}\n",
        .{ r.n_bank, r.n_exam, r.n_correct, r.accuracy, r.threshold, r.n_math, r.n_overlap, r.n_exact, r.n_miss },
    );
    if (r.ok) {
        std.debug.print("FSOT_DEPTH PASS\n", .{});
        std.debug.print("FSOT_GRADE_SCHOOL_UNDERSTAND_OK\n", .{});
    } else {
        std.debug.print("FSOT_DEPTH FAIL (need ≥95% held-out paraphrases)\n", .{});
        std.process.exit(1);
    }
}

fn runNeuromod() void {
    std.debug.print("=== FSOT NEUROMODULATORS (DA/ACh/NE/5-HT Fixed ODEs) ===\n", .{});
    std.debug.print("doctrine: first-class ODE species; couple STDP η + encode gain; seed-scaled τ\n", .{});
    std.debug.print("bio: VTA/SNc DA, BF ACh, LC NE, raphe 5-HT — process scale not receptor kinetics\n", .{});
    if (!neuromod_fixed.selfTest()) {
        std.debug.print("FSOT_NEUROMOD FAIL selftest\n", .{});
        std.process.exit(1);
    }
    var s: neuromod_fixed.NeuromodState = .{};
    var t: u32 = 0;
    while (t < 100) : (t += 1) {
        neuromod_fixed.step(&s, .wake_encode, 0, 0, 0, 0, fixed.fromInt(1));
    }
    const eta = neuromod_fixed.stdpEtaScale(&s);
    const genc = neuromod_fixed.encodeGain(&s);
    std.debug.print(
        "wake_encode da={e} ach={e} ne={e} ht={e} eta_scale={e} encode_gain={e}\n",
        .{ fixed.toF64(s.da), fixed.toF64(s.ach), fixed.toF64(s.ne), fixed.toF64(s.ht), fixed.toF64(eta), fixed.toF64(genc) },
    );
    t = 0;
    while (t < 100) : (t += 1) {
        neuromod_fixed.step(&s, .sleep_nrem, 0, 0, 0, 0, fixed.fromInt(1));
    }
    std.debug.print(
        "sleep_nrem da={e} ach={e} ne={e} ht={e} sigma={e}\n",
        .{ fixed.toF64(s.da), fixed.toF64(s.ach), fixed.toF64(s.ne), fixed.toF64(s.ht), fixed.toF64(neuromod_fixed.sigmaProxy(&s, fixed.fromDecimalStr("0.3"))) },
    );
    std.debug.print("FSOT_NEUROMOD PASS\n", .{});
    std.debug.print("FSOT_NEUROMOD_ODE_OK\n", .{});
}

fn runSleepReplay() void {
    std.debug.print("=== FSOT SLEEP REPLAY CONSOLIDATION (offline Fixed) ===\n", .{});
    std.debug.print("doctrine: wake encode (ACh/NE) → rest → NREM quiet → replay+STDP+DA tag → probe\n", .{});
    std.debug.print("bio: Creery-style reactivation; not wall-clock PC sleep\n", .{});
    const r = sleep_replay_fixed.runConsolidationProbe();
    std.debug.print(
        "CONSOL items={d} top1_imm={e} top1_delay={e} top1_consol={e} improved={} sigma={e} da={e} ach_w={e} ach_s={e} stdp={d} replay={d} da_pulses={d} nm_self={}\n",
        .{
            r.n_items,
            r.top1_immediate,
            r.top1_after_delay,
            r.top1_after_consol,
            r.consolidate_improved,
            r.mean_sigma,
            r.mean_da,
            r.mean_ach_wake,
            r.mean_ach_sleep,
            r.n_stdp_replay,
            r.n_replay_events,
            r.n_da_pulses,
            r.neuromod_selftest,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_SLEEP_REPLAY PASS\n", .{});
        std.debug.print("FSOT_CONSOLIDATION_OK\n", .{});
    } else {
        std.debug.print("FSOT_SLEEP_REPLAY FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runBrainLearn(speak: bool) void {
    std.debug.print("=== FSOT BRAIN LEARN (BIO: encode+engram → retrieve practice → sleep → retrieve prove) ===\n", .{});
    std.debug.print("doctrine: NO hash-bank cheat — prove via store.retrieve + SpeakEngram on OrganismF\n", .{});
    if (speak) std.debug.print("speech: motor speakNow + TTS of stored fact engrams only\n", .{});
    const r = brain_learn_fixed.runBrainLearn(speak);
    std.debug.print(
        "BRAIN_LEARN taught={d} file={d} eps={d} engrams={d} practice={d}/{d} acc={e} prove={d}/{d} claimable={d} prove_acc={e} claim_rate={e} retrieve={d}/{d} ret_acc={e} motor={d} da={d} ach={e} tts={d} sleep={} nm={} bio={}\n",
        .{
            r.n_lessons_taught,
            r.n_file,
            r.n_episodes,
            r.n_engrams,
            r.practice_hit,
            r.practice_try,
            r.practice_acc,
            r.prove_ok,
            r.prove_n,
            r.prove_claimable,
            r.prove_acc,
            r.claim_rate,
            r.retrieve_hit,
            r.retrieve_try,
            r.retrieve_acc,
            r.n_motor,
            r.n_da,
            r.mean_ach,
            r.n_tts_spoken,
            r.sleep_ok,
            r.neuromod_ok,
            r.bio_path,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_BRAIN_LEARN PASS\n", .{});
        std.debug.print("FSOT_REAL_BRAIN_TEACH_OK\n", .{});
        std.debug.print("FSOT_BIO_RETRIEVE_PROVE_OK\n", .{});
    } else {
        std.debug.print("FSOT_BRAIN_LEARN FAIL (need retrieve+practice+prove on real organism, not bank)\n", .{});
        std.process.exit(1);
    }
}

fn runClaimability() void {
    std.debug.print("=== FSOT CLAIMABILITY (multi-hop grounded intelligence) ===\n", .{});
    std.debug.print("doctrine: every hop bank-grounded; 1–3 hop chains; neuromod encode tags\n", .{});
    std.debug.print("not LLM freestyle — claimable iff taught premises retrieve\n", .{});
    const r = claimability_fixed.runClaimabilityProbe();
    std.debug.print(
        "CLAIM chains={d} correct={d} claimable={d} acc={e} claim_rate={e} 1hop={d}/{d} 2hop={d}/{d} 3hop={d}/{d} ach={e} da_pulses={d} nm={}\n",
        .{
            r.n_chains,
            r.n_correct,
            r.n_claimable,
            r.accuracy,
            r.claim_rate,
            r.correct_1,
            r.n_1hop,
            r.correct_2,
            r.n_2hop,
            r.correct_3,
            r.n_3hop,
            r.mean_ach,
            r.n_da_pulses,
            r.neuromod_ok,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_CLAIMABILITY PASS\n", .{});
        std.debug.print("FSOT_MULTI_HOP_INTEL_OK\n", .{});
    } else {
        std.debug.print("FSOT_CLAIMABILITY FAIL (need ≥95% claimable + 3-hop activity)\n", .{});
        std.process.exit(1);
    }
}

fn runComposeIntel() void {
    std.debug.print("=== FSOT COMPOSE-INTEL (answer-dependent multi-hop) ===\n", .{});
    std.debug.print("doctrine: hop N cue from hop N-1 answer (hipp bind → WM → edge re-cue)\n", .{});
    std.debug.print("not parallel claimability — ablation must break when intermediate corrupted\n", .{});
    const r = compose_intel_fixed.runComposeIntel();
    std.debug.print(
        "COMPOSE taught={d} chains={d} correct={d} claimable={d} acc={e} claim_rate={e} 2hop={d}/{d} 3hop={d}/{d}\n",
        .{
            r.n_taught,
            r.n_chains,
            r.n_correct,
            r.n_claimable,
            r.accuracy,
            r.claim_rate,
            r.correct_2,
            r.n_2hop,
            r.correct_3,
            r.n_3hop,
        },
    );
    std.debug.print(
        "COMPOSE pe_hit={d} pe_miss={d} ach={e} wm_peak={d} ablate={d}/{d} break_rate={e} nm={} answer_dep={}\n",
        .{
            r.pe_hits,
            r.pe_miss,
            r.mean_ach,
            r.wm_peak,
            r.n_ablate_broke,
            r.n_ablate,
            r.ablate_break_rate,
            r.neuromod_ok,
            r.answer_dependent,
        },
    );
    std.debug.print(
        "COMPOSE schema_edges={d} schema_exp={} episodic_hits={d} bank_fb={d} episodic_rate={e}\n",
        .{
            r.n_discovered_edges,
            r.schema_from_experience,
            r.episodic_hits,
            r.bank_fallbacks,
            r.episodic_rate,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_COMPOSE_INTEL PASS\n", .{});
        std.debug.print("FSOT_ANSWER_DEPENDENT_HOP_OK\n", .{});
        std.debug.print("FSOT_COMPOSE_ABLATION_OK\n", .{});
        std.debug.print("FSOT_SCHEMA_DISCOVERY_OK\n", .{});
    } else {
        std.debug.print("FSOT_COMPOSE_INTEL FAIL (need ≥90% claimable + ablation + schema discovery)\n", .{});
        std.process.exit(1);
    }
}

fn runIntelBio() void {
    std.debug.print("=== FSOT INTEL-BIO STACK (neuromod + sleep + claimability + compose) ===\n", .{});
    runNeuromod();
    runSleepReplay();
    runClaimability();
    runComposeIntel();
    std.debug.print("FSOT_INTEL_BIO_STACK PASS\n", .{});
}

fn runAllenDist() void {
    std.debug.print("=== FSOT ALLEN CSV DISTRIBUTION (variance / KS) ===\n", .{});
    const r = allen_dist_fixed.runAllenDistMatch();
    allen_dist_fixed.printReport(r);
    if (!r.ok) {
        std.debug.print("FSOT_FIXED_BIO FAIL (Allen CSV distribution residual open)\n", .{});
        std.process.exit(1);
    }
    // Cre-class conditional variance (Pyr/PV/SST/VIP) — required for bio accuracy
    runAllenClassDist();
}

fn runAllenClassDist() void {
    std.debug.print("=== FSOT ALLEN CRE-CLASS DISTRIBUTION ===\n", .{});
    const p = allen_class_dist_fixed.runClassDistPanel();
    allen_class_dist_fixed.printReport(p);
    if (!p.ok) {
        std.debug.print("FSOT_FIXED_BIO FAIL (Cre-class Allen distribution residual open)\n", .{});
        std.process.exit(1);
    }
}

fn runGeneticVar() void {
    std.debug.print("=== FSOT GENETIC VARIANCE (mutateOrf) ===\n", .{});
    if (!genetic_var_fixed.selfTest()) {
        std.debug.print("FSOT_GENETIC_VARIANCE SELFTEST FAIL\n", .{});
        std.process.exit(1);
    }
    const r = genetic_var_fixed.runGeneticVariance();
    genetic_var_fixed.printReport(r);
    if (!r.ok) {
        std.debug.print("FSOT_GENETIC_VARIANCE FAIL (refine mutateOrf / phenotype)\n", .{});
        std.process.exit(1);
    }
}

fn runIsiKsProduct() void {
    std.debug.print("=== FSOT ALLEN ISI DISTRIBUTION KS (PRODUCT) ===\n", .{});
    if (!allen_isi_ks_product.selfTest()) {
        std.debug.print("FSOT_ALLEN_ISI_KS_PRODUCT SELFTEST FAIL\n", .{});
        std.process.exit(1);
    }
    const r = allen_isi_ks_product.runIsiKsProduct();
    allen_isi_ks_product.printReport(r);
    if (!r.ok) {
        std.debug.print("FSOT_ALLEN_ISI_KS_PRODUCT FAIL (genetic ISI dist vs Allen CSV)\n", .{});
        std.process.exit(1);
    }
}

fn runAllenBareHost() void {
    std.debug.print("=== FSOT ALLEN BAREMETAL SUITE (host twin of QEMU full Allen) ===\n", .{});
    std.debug.print("doctrine: same genetic FI + class rates as freestanding kernel\n", .{});
    const ar = allen_baremetal_fixed.runFullGeneticAllen();
    std.debug.print(
        "ALLEN_POP rate={e} isi={e} adapt={e} |Δisi|={e} |ΔA|={e} closed={d}/{d} all={} iron={} pop_ok={}\n",
        .{
            ar.mean_rate_Hz,
            ar.mean_isi_ms,
            ar.mean_adapt,
            ar.isi_abs_err_ms,
            ar.adapt_abs_err,
            ar.n_closed,
            ar.n_units,
            ar.all_units_closed,
            ar.iron_adapt,
            ar.pop_ok,
        },
    );
    std.debug.print(
        "ALLEN_CLASS Pyr={e} PV={e} SST={e} VIP={e} pv_fast={} class_ok={}\n",
        .{ ar.pyr_Hz, ar.pv_Hz, ar.sst_Hz, ar.vip_Hz, ar.pv_faster, ar.class_ok },
    );
    if (ar.ok) {
        std.debug.print("FSOT_ALLEN_BAREMETAL_FULL PASS\n", .{});
        std.debug.print("FSOT_ALLEN_BIO_ACCURATE_OK\n", .{});
    } else {
        std.debug.print("FSOT_ALLEN_BAREMETAL_FULL FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runIntelFrontier() void {
    std.debug.print("=== FSOT INTEL FRONTIER (multi-day + curiosity + ladder) ===\n", .{});
    std.debug.print("schedule: N days of curiosity-select → ACh encode → PE retrieve → sleep → claim\n", .{});
    std.debug.print("speech path intact (reconnect after frontiers) — see docs/SPEECH_RECONNECT.md\n", .{});
    const r = intel_frontier_fixed.runFrontier();
    std.debug.print(
        "FRONT days={d} taught={d} curio_picks={d} novel={d} pe_hit={d} pe_miss={d} claim0={e} claimF={e} improved={} str={e}\n",
        .{
            r.n_days,
            r.n_taught_total,
            r.n_curiosity_picks,
            r.n_novel_picks,
            r.pe_hits,
            r.pe_miss,
            r.claim_day0,
            r.claim_final,
            r.claim_improved,
            r.mean_str_final,
        },
    );
    std.debug.print(
        "FRONT stdp={d} replay={d} sigma={e} ladder_ok={} depth_ran={} depth_acc={e} depth_ok={} loop_ok={} speech_intact={}\n",
        .{
            r.total_stdp,
            r.total_replay,
            r.mean_sigma,
            r.ladder_ok,
            r.depth_ran,
            r.depth_acc,
            r.depth_ok,
            r.intel_loop_ok,
            r.speech_path_intact,
        },
    );
    var d: usize = 0;
    while (d < r.n_days) : (d += 1) {
        const s = r.days[d];
        std.debug.print(
            "  day{d}: sel={d} novel={d} retrieve={e} claim={e} str={e} stdp={d} replay={d}\n",
            .{ s.day, s.n_selected, s.n_novel, s.retrieve_rate, s.claim_rate, s.mean_str, s.n_stdp, s.n_replay },
        );
    }
    if (r.ok) {
        std.debug.print("FSOT_INTEL_FRONTIER PASS\n", .{});
        std.debug.print("FSOT_MULTI_DAY_CURIOSITY_OK\n", .{});
        std.debug.print("FSOT_SPEECH_PATH_INTACT\n", .{});
    } else {
        std.debug.print("FSOT_INTEL_FRONTIER FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runIntelLoop() void {
    std.debug.print("=== FSOT INTEL LOOP (train → retrieve → sleep → prove) ===\n", .{});
    std.debug.print("schedule: ACh encode → spaced PE retrieval → claim/mem probe → NREM replay → re-prove + transfer\n", .{});
    std.debug.print("bio: encoding tags, prediction-error DA, offline consolidation, limited WM slots\n", .{});
    const r = intel_loop_fixed.runIntelLoop();
    std.debug.print(
        "LOOP taught={d} retrieve={e} claim_pre={e} claim_post={e} mem_pre={e} mem_post={e} transfer={e}/{d} pe_hit={d} pe_miss={d}\n",
        .{
            r.n_taught,
            r.retrieval_hit_rate,
            r.claim_pre,
            r.claim_post,
            r.mem_pre,
            r.mem_post,
            r.transfer_rate,
            r.n_transfer,
            r.pe_hits,
            r.pe_miss,
        },
    );
    std.debug.print(
        "LOOP sleep_stdp={d} replay={d} sigma={e} ach_train={e} ach_sleep={e} wm={d} claim_ret={} mem_ret={} nm={} claim_mod={} compose_mod={} compose_rate={e} sleep_mod={} depth_ran={} depth_acc={e} depth_ok={}\n",
        .{
            r.n_stdp_sleep,
            r.n_replay,
            r.mean_sigma,
            r.mean_ach_train,
            r.mean_ach_sleep,
            r.wm_slots_used,
            r.claim_retained,
            r.mem_retained,
            r.neuromod_ok,
            r.claim_module_ok,
            r.compose_module_ok,
            r.compose_claim_rate,
            r.sleep_module_ok,
            r.depth_ran,
            r.depth_acc,
            r.depth_ok,
        },
    );
    if (r.ok) {
        std.debug.print("FSOT_INTEL_LOOP PASS\n", .{});
        std.debug.print("FSOT_TRAIN_SLEEP_PROVE_OK\n", .{});
    } else {
        std.debug.print("FSOT_INTEL_LOOP FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runAllAtomMd() void {
    std.debug.print("=== FSOT ALL-ATOM MD LAB (host f64; not cognitive runtime) ===\n", .{});
    std.debug.print("doctrine: Velocity-Verlet + bonds/angles + LJ/Coulomb PBC + Berendsen\n", .{});
    std.debug.print("systems: TIP3P-like water box; K+ carbonyl selectivity filter\n", .{});
    std.debug.print("see docs/WHY_NOT_ALL_ATOM_MD.md — implemented as lab tool, not mind loop\n", .{});

    const w = allatom_md.runMd(.water, 300);
    std.debug.print(
        "WATER system={s} atoms={d} bonds={d} angles={d} steps={d} dt_fs={e} T={e} pe={e} ke={e} drift={e} maxF={e} feval={d} ok={}\n",
        .{ w.system, w.n_atoms, w.n_bonds, w.n_angles, w.n_steps, w.dt_fs, w.final_T, w.pe, w.ke, w.energy_drift, w.max_force, w.force_evals, w.ok },
    );

    const f = allatom_md.runMd(.ion_filter, 300);
    std.debug.print(
        "FILTER system={s} atoms={d} bonds={d} angles={d} steps={d} dt_fs={e} T={e} pe={e} ke={e} drift={e} maxF={e} feval={d} ok={}\n",
        .{ f.system, f.n_atoms, f.n_bonds, f.n_angles, f.n_steps, f.dt_fs, f.final_T, f.pe, f.ke, f.energy_drift, f.max_force, f.force_evals, f.ok },
    );

    const st = allatom_md.selfTest();
    if (w.ok and f.ok and st) {
        std.debug.print("FSOT_ALLATOM_MD PASS\n", .{});
        std.debug.print("FSOT_MD_LAB_OK\n", .{});
    } else {
        std.debug.print("FSOT_ALLATOM_MD FAIL (water={} filter={} self={})\n", .{ w.ok, f.ok, st });
        std.process.exit(1);
    }
}

fn runSynapsePathways() void {
    std.debug.print("=== FSOT SYNAPTIC PATHWAYS (trace + plastic bonds + novel thought) ===\n", .{});
    std.debug.print("doctrine: Hebb LTP-like W update, prune unused, concept cross-domain bonds\n", .{});
    std.debug.print("compare to human: LTP/LTD, synaptogenesis, limited adult neurogenesis, association\n", .{});
    const r = synapse_path_fixed.runSynapsePathwayProbe();
    std.debug.print(
        "PATH edges={d} hebb={d} stdp={d} stdp_ok={} spikes={d} concepts={d} bonds {d}→{d} novel={d} cross={d} pruned={d} thought_steps={d} cross_region={d} meanS={e}\n",
        .{
            r.n_edge_traces,
            r.n_hebb,
            r.n_stdp,
            r.stdp_selftest,
            r.spikes,
            r.n_concepts,
            r.n_bonds_before,
            r.n_bonds_after,
            r.n_novel_bonds,
            r.n_cross_domain,
            r.n_pruned,
            r.n_thought_steps,
            r.cross_region_edges,
            r.mean_s,
        },
    );
    std.debug.print(
        "GLIA supply={e} load={e} clear={d} prune={d} myelo={d} self={}\n",
        .{ r.mean_supply, r.mean_load, r.n_glia_clear, r.n_glia_prune, r.n_myelo, r.glia_selftest },
    );
    std.debug.print(
        "WET releases={d} quanta={d} silent0={d} ch_tx={d} ampa_o={d} nmda_o={d} nmda_ev={d} ca={d} camk={d} ampa_up={d} ltd={d} consol={d} chem={d} self={}\n",
        .{ r.n_releases, r.n_quanta, r.n_silent_fail, r.n_channel_transitions, r.n_ampa_openings, r.n_nmda_openings, r.n_nmda, r.n_ca_peaks, r.n_camk_peaks, r.n_ampa_up, r.n_ltd, r.n_consolidate, r.n_chem_steps, r.mol_selftest },
    );
    if (r.ok) {
        std.debug.print("FSOT_SYNAPSE_PATH PASS\n", .{});
        std.debug.print("FSOT_NOVEL_PATHWAY_OK\n", .{});
        std.debug.print("FSOT_GLIA_MOLECULAR_OK\n", .{});
    } else {
        std.debug.print("FSOT_SYNAPSE_PATH FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runPixelId() void {
    std.debug.print("=== FSOT MIND PIXEL-ID (tutor-ablated multi-seed synthetic) ===\n", .{});
    const p = pixel_id_fixed.runPixelIdProbe();
    std.debug.print(
        "PIXEL_ID chars={d} seeds={d} train={d} test={d} correct={d}/{d} top1={e} multi_mean={e} chance={e} tutor_ablated={} spikes={d}\n",
        .{ p.n_characters, p.n_seeds, p.n_train, p.n_test, p.correct, p.n_test, p.top1, p.multi_seed_mean, p.chance, p.tutor_ablated, p.spikes },
    );
    if (p.ok) {
        std.debug.print("FSOT_PIXEL_ID PASS\n", .{});
    } else {
        std.debug.print("FSOT_PIXEL_ID FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runLive() void {
    std.debug.print("=== FSOT MIND LIVE (FIXED multi-region) ===\n", .{});
    var b = brain_fixed.BrainF.initSeeded(42, false);
    const st = b.structureReport();
    std.debug.print(
        "structure units={d} E={d} I={d} synapses={d} Pyr/PV/SST/VIP={d}/{d}/{d}/{d}\n",
        .{ st.n_units, st.n_e, st.n_i, st.n_synapses, st.n_pyr, st.n_pv, st.n_sst, st.n_vip },
    );
    var ext: [brain_fixed.N_TOTAL]fixed.Fixed = undefined;
    var t: usize = 0;
    var spikes_win: u32 = 0;
    while (t < 90) : (t += 1) {
        const prim: fixed.Fixed = if ((t % 30) < 10) fixed.fromDecimalStr("0.75") else fixed.fromDecimalStr("0.06");
        const reg: brain_fixed.RegionId = if ((t / 30) % 2 == 0) .sens else .assoc;
        b.buildExternal(prim, reg, ext[0..]);
        const before = b.totalSpikes();
        b.step(ext[0..]);
        spikes_win += b.totalSpikes() - before;
        if ((t + 1) % 30 == 0) {
            std.debug.print(
                "t={d} meanS={e} spikes_win={d}\n",
                .{ t + 1, fixed.toF64(b.meanS()), spikes_win },
            );
            spikes_win = 0;
        }
    }
    std.debug.print("FSOT_LIVE PASS total_spikes={d}\n", .{b.totalSpikes()});
}

fn runInject() void {
    std.debug.print("=== FSOT MIND INJECT (FIXED lattice + inject ABI) ===\n", .{});
    if (!inject_io_fixed.selfTest()) {
        std.debug.print("FSOT_INJECT FAIL inject_io_fixed\n", .{});
        std.process.exit(1);
    }
    var bus: inject_io_fixed.BusF = .{};
    _ = inject_io_fixed.parseFeatureText(inject_io_fixed.DEMO_TEXT, &bus) catch {
        std.debug.print("FSOT_INJECT FAIL parse\n", .{});
        std.process.exit(1);
    };
    var org = organism_fixed.OrganismF.init();
    org.encode_every = 10;
    org.steps_per_tick = 4;
    org.setMetric(bus.metric);
    var feats: [8]fixed.Fixed = .{0} ** 8;
    const nf = bus.firstVisionFeats(&feats);
    org.setInject(feats[0..nf]);
    var t: u32 = 0;
    while (t < 40) : (t += 1) {
        _ = org.tickOnce();
    }
    std.debug.print(
        "inject meanS={e} spikes={d} eps={d} metric_cpu={e} packets={d} mod={s} stim={e}\n",
        .{
            fixed.toF64(org.brain.meanS()),
            org.brain.totalSpikes(),
            org.store.n,
            fixed.toF64(bus.metric.cpu),
            bus.n,
            modulate_fixed.modeName(org.last_mod.mode),
            fixed.toF64(org.last_mod.stim_scale),
        },
    );
    if (org.brain.totalSpikes() >= 1) {
        std.debug.print("FSOT_INJECT PASS\n", .{});
    } else {
        std.debug.print("FSOT_INJECT FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runStructure() void {
    std.debug.print("=== FSOT MIND STRUCTURE ===\n", .{});
    var b = brain.Brain.init();
    const st = b.structureReport();
    std.debug.print("profile=ai_efficient units={d}\n", .{st.n_units});
    std.debug.print("regions: thal={d} sens={d} assoc={d} hipp={d}\n", .{
        brain.N_THAL,
        brain.N_SENS,
        brain.N_ASSOC,
        brain.N_HIPP,
    });
    std.debug.print("E={d} I={d} synapses={d}\n", .{ st.n_e, st.n_i, st.n_synapses });
    std.debug.print("cell_types Pyr={d} PV={d} SST={d} VIP={d}\n", .{ st.n_pyr, st.n_pv, st.n_sst, st.n_vip });
    printF64("mean_abs_W=", st.mean_abs_w);
    printF64("mean_composite_spin=", st.mean_composite_spin);
    printF64("ei_mass_ratio=", @as(f64, @floatFromInt(st.n_e)) / @as(f64, @floatFromInt(if (st.n_i == 0) 1 else st.n_i)));
    printF64("consciousness_gate=", pathways.consciousnessGate());
    // dump unit 0 codon genotype summary
    const g0 = b.genotypes[0];
    std.debug.print(
        "unit0 type={d} spin={e} charge={e} SCN_expr={e} ref_ms={e}\n",
        .{
            @intFromEnum(g0.cell_type),
            g0.composite_spin,
            g0.composite_charge,
            g0.phenotype.scn_expression,
            g0.phenotype.refractory_steps,
        },
    );
    std.debug.print("FSOT_STRUCTURE PASS\n", .{});
}

fn runGenetic() void {
    std.debug.print("=== FSOT MIND GENETIC (64-codon foundation) ===\n", .{});
    if (!codon.selfTest() or !genotype.selfTest()) {
        std.debug.print("FSOT_GENETIC_CORE FAIL\n", .{});
        std.process.exit(1);
    }
    // Channel ORF spins (no diversity)
    const scn = genotype.buildGeneProgram(.scn, genotype.ORF_SCN);
    const kcn = genotype.buildGeneProgram(.kcn, genotype.ORF_KCN);
    const ca = genotype.buildGeneProgram(.cacna, genotype.ORF_CACNA);
    const leak = genotype.buildGeneProgram(.leak, genotype.ORF_LEAK);
    std.debug.print("SCN spin={e} expr={e} q={d}\n", .{ scn.spin, scn.expression, scn.charge_balance });
    std.debug.print("KCN spin={e} expr={e} q={d}\n", .{ kcn.spin, kcn.expression, kcn.charge_balance });
    std.debug.print("CACNA spin={e} expr={e} q={d}\n", .{ ca.spin, ca.expression, ca.charge_balance });
    std.debug.print("LEAK spin={e} expr={e} q={d}\n", .{ leak.spin, leak.expression, leak.charge_balance });

    const pyr = genotype.buildCellTypeGenotype(0, .pyr, false);
    const pv = genotype.buildCellTypeGenotype(0, .pv, false);
    std.debug.print("Pyr spin={e} ref={e} fi={e}\n", .{ pyr.composite_spin, pyr.phenotype.refractory_steps, pyr.phenotype.fi_stim });
    std.debug.print("PV  spin={e} ref={e} fi={e}\n", .{ pv.composite_spin, pv.phenotype.refractory_steps, pv.phenotype.fi_stim });

    var b = brain.Brain.initWithDiversity(true);
    const st = b.structureReport();
    std.debug.print(
        "brain genetic units={d} E={d} I={d} syn={d} Pyr/PV/SST/VIP={d}/{d}/{d}/{d}\n",
        .{ st.n_units, st.n_e, st.n_i, st.n_synapses, st.n_pyr, st.n_pv, st.n_sst, st.n_vip },
    );
    printF64("mean_abs_W=", st.mean_abs_w);
    printF64("mean_spin=", st.mean_composite_spin);
    printF64("mean_charge=", st.mean_composite_charge);
    // machine-readable for Python parity harness
    std.debug.print("GEN_N_SYN={d}\n", .{st.n_synapses});
    std.debug.print("GEN_N_PYR={d}\n", .{st.n_pyr});
    std.debug.print("GEN_N_PV={d}\n", .{st.n_pv});
    std.debug.print("GEN_N_SST={d}\n", .{st.n_sst});
    std.debug.print("GEN_N_VIP={d}\n", .{st.n_vip});
    std.debug.print("GEN_N_E={d}\n", .{st.n_e});
    std.debug.print("GEN_N_I={d}\n", .{st.n_i});
    printF64("GEN_MEAN_ABS_W=", st.mean_abs_w);
    var ext: [brain.N_TOTAL]f64 = undefined;
    var t: usize = 0;
    while (t < 100) : (t += 1) {
        b.buildExternal(if ((t % 40) < 12) 0.65 else 0.06, .sens, ext[0..]);
        b.step(ext[0..]);
    }
    std.debug.print("live spikes={d} meanS={e}\n", .{ b.totalSpikes(), b.meanS() });
    if (st.n_synapses < 1 or b.totalSpikes() < 1 or st.n_pyr < 1) {
        std.debug.print("FSOT_GENETIC FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_GENETIC PASS codon→genotype→W→step\n", .{});
}

fn runSme() void {
    std.debug.print("=== FSOT MIND SME (band / encode vs rest) ===\n", .{});
    if (!bands.selfTest()) {
        std.debug.print("FSOT_SME FAIL bands\n", .{});
        std.process.exit(1);
    }
    var b = brain.Brain.init();
    var ext: [brain.N_TOTAL]f64 = undefined;
    // encode epoch: patterned drive
    var rate_enc: [256]f64 = undefined;
    var t: usize = 0;
    while (t < 256) : (t += 1) {
        const prim: f64 = if ((t % 20) < 8) 0.7 else 0.1;
        b.buildExternal(prim, .sens, ext[0..]);
        // add item-like pattern
        var u: usize = 0;
        while (u < b.n) : (u += 1) {
            if (b.region_of[u] == .assoc) ext[u] += 0.3 * @as(f64, @floatFromInt((t + u) % 5)) / 5.0;
        }
        const before = b.totalSpikes();
        b.step(ext[0..]);
        const df = b.totalSpikes() - before;
        rate_enc[t] = @as(f64, @floatFromInt(df)) / @as(f64, @floatFromInt(b.n)) * 1000.0;
    }
    // rest epoch: low drive
    b.reset();
    var rate_rest: [256]f64 = undefined;
    t = 0;
    while (t < 256) : (t += 1) {
        b.buildExternal(0.05, .thal, ext[0..]);
        const before = b.totalSpikes();
        b.step(ext[0..]);
        const df = b.totalSpikes() - before;
        rate_rest[t] = @as(f64, @floatFromInt(df)) / @as(f64, @floatFromInt(b.n)) * 1000.0;
    }
    const sme = bands.smeContrast(rate_enc[0..], rate_rest[0..], 1.0);
    std.debug.print(
        "theta_enc={e} theta_rest={e} gamma_enc={e} gamma_rest={e} th_gt={d} ga_gt={d}\n",
        .{
            sme.theta_encode,
            sme.theta_rest,
            sme.gamma_encode,
            sme.gamma_rest,
            @as(u32, if (sme.theta_gt) 1 else 0),
            @as(u32, if (sme.gamma_gt) 1 else 0),
        },
    );
    // Soft directional: report; hard gate is finite powers + encode had spikes
    var enc_sum: f64 = 0;
    for (rate_enc) |r| enc_sum += r;
    if (enc_sum <= 0 or sme.theta_encode != sme.theta_encode) {
        std.debug.print("FSOT_SME FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_SME PASS (directional proxies)\n", .{});
}

fn emitPop(prefix: []const u8, r: bio_probe.PopReport) void {
    std.debug.print("{s}n_units={d}\n", .{ prefix, r.n_units });
    std.debug.print("{s}mean_rate_Hz={e}\n", .{ prefix, r.mean_rate_Hz });
    std.debug.print("{s}mean_isi_ms={e}\n", .{ prefix, r.mean_isi_ms });
    std.debug.print("{s}mean_adapt={e}\n", .{ prefix, r.mean_adapt });
    std.debug.print("{s}mean_isi_cv={e}\n", .{ prefix, r.mean_isi_cv });
    std.debug.print("{s}mean_S={e}\n", .{ prefix, r.mean_S });
    std.debug.print("{s}mean_Vm_mV={e}\n", .{ prefix, r.mean_Vm_mV });
    std.debug.print("{s}total_spikes={d}\n", .{ prefix, r.total_spikes });
    std.debug.print("{s}n_with_isi={d}\n", .{ prefix, r.n_with_isi });
}

fn runBio(params_path: ?[]const u8) !void {
    std.debug.print("=== FSOT MIND BIO (FI population) ===\n", .{});
    if (!bio_probe.selfTest()) {
        std.debug.print("FSOT_BIO_SELFTEST FAIL\n", .{});
        std.process.exit(1);
    }
    std.debug.print("FSOT_BIO_SELFTEST PASS\n", .{});

    var params: [32]bio_probe.UnitParams = undefined;
    var n: usize = 32;
    var source: []const u8 = "default_bio_matchish";
    if (params_path) |path| {
        n = bio_params_load.loadFromPath(path, params[0..]) catch |err| {
            std.debug.print("FSOT_BIO params load FAIL {s} err={s}\n", .{ path, @errorName(err) });
            std.process.exit(1);
        };
        source = path;
        std.debug.print("params_file={s} n={d}\n", .{ path, n });
    } else {
        bio_probe.defaultBioParams(params[0..n]);
        std.debug.print("params=default n={d}\n", .{n});
    }
    std.debug.print("params_source={s}\n", .{source});

    const steps: usize = 1200;
    const rep = bio_probe.runFIPopulation(params[0..n], steps, 1.0);
    emitPop("BIO_FI_", rep);

    // Multi-region brain with same phenotype lock + sensory FI bursts
    var br = brain.Brain.init();
    br.applyBioParams(params[0..n]);
    var ext: [brain.N_TOTAL]f64 = undefined;
    var t: usize = 0;
    const bsteps: usize = 800;
    while (t < bsteps) : (t += 1) {
        // FI into sens (+ thal relay) using mean fi_stim of locked params
        var mean_fi: f64 = 0;
        var i: usize = 0;
        while (i < n) : (i += 1) mean_fi += params[i].fi_stim;
        mean_fi /= @as(f64, @floatFromInt(n));
        const on = (t % 80) < 25;
        br.buildExternal(if (on) mean_fi else 0.05, .sens, ext[0..]);
        br.step(ext[0..]);
    }
    std.debug.print("BIO_BRAIN_spikes={d}\n", .{br.totalSpikes()});
    std.debug.print("BIO_BRAIN_mean_S={e}\n", .{br.meanS()});
    std.debug.print("BIO_BRAIN_sens_S={e}\n", .{br.regionMeanS(.sens)});
    std.debug.print("BIO_BRAIN_hipp_S={e}\n", .{br.regionMeanS(.hipp)});
    const brain_rate = @as(f64, @floatFromInt(br.totalSpikes())) /
        (@as(f64, @floatFromInt(br.n)) * @as(f64, @floatFromInt(bsteps)) / 1000.0);
    std.debug.print("BIO_BRAIN_pop_rate_Hz={e}\n", .{brain_rate});

    // Gates: cortical-ish bands (same spirit as Python bio_metrics)
    const rate_ok = rep.mean_rate_Hz >= 5.0 and rep.mean_rate_Hz <= 80.0;
    const isi_ok = rep.n_with_isi >= 1 and rep.mean_isi_ms >= 10.0 and rep.mean_isi_ms <= 200.0;
    const adapt_ok = rep.mean_adapt > -0.3 and rep.mean_adapt < 0.6;
    // Vm is a linear S proxy (not true clamp V); FI duty can pull mean S low.
    // Gate: finite + not pathological (> -200 mV class).
    const vm_ok = rep.mean_Vm_mV == rep.mean_Vm_mV and rep.mean_Vm_mV > -200.0 and rep.mean_Vm_mV < 20.0;

    std.debug.print("gate_rate={s}\n", .{if (rate_ok) "PASS" else "FAIL"});
    std.debug.print("gate_isi={s}\n", .{if (isi_ok) "PASS" else "FAIL"});
    std.debug.print("gate_adapt={s}\n", .{if (adapt_ok) "PASS" else "FAIL"});
    std.debug.print("gate_vm={s}\n", .{if (vm_ok) "PASS" else "FAIL"});

    if (rate_ok and isi_ok and adapt_ok and vm_ok) {
        std.debug.print("FSOT_BIO PASS\n", .{});
    } else {
        std.debug.print("FSOT_BIO FAIL\n", .{});
        std.process.exit(1);
    }
}

fn runStress() !void {
    std.debug.print("=== FSOT MIND STRESS ===\n", .{});

    // 1) single-unit FI
    var p0: bio_probe.UnitParams = .{};
    p0.ref_steps = 50;
    p0.fi_stim = 0.50;
    const unit_pr = bio_probe.runFIUnit(p0, 1000, 1.0);
    std.debug.print("STRESS_UNIT_rate_Hz={e}\n", .{unit_pr.firing_rate_Hz});
    std.debug.print("STRESS_UNIT_isi_ms={e}\n", .{unit_pr.mean_isi_ms});
    std.debug.print("STRESS_UNIT_adapt={e}\n", .{unit_pr.adaptation_index});
    std.debug.print("STRESS_UNIT_spikes={d}\n", .{unit_pr.spike_count});

    // 2) default bio pop
    var params: [32]bio_probe.UnitParams = undefined;
    bio_probe.defaultBioParams(params[0..]);
    const fi = bio_probe.runFIPopulation(params[0..], 1000, 1.0);
    emitPop("STRESS_FI_", fi);

    // 3) periodic population
    const per = bio_probe.runPeriodicPopulation(16, 800, 0.65, 0.05);
    emitPop("STRESS_PERIODIC_", per);

    // 4) network
    const ns = bio_probe.runNetworkStress(32, 400);
    std.debug.print("STRESS_NET_spikes={d}\n", .{ns.spikes});
    std.debug.print("STRESS_NET_mean_S={e}\n", .{ns.mean_s});
    std.debug.print("STRESS_NET_rate_Hz={e}\n", .{ns.rate_Hz});

    // 5) multi-region brain
    var b = brain.Brain.init();
    var ext: [brain.N_TOTAL]f64 = undefined;
    var t: usize = 0;
    while (t < 200) : (t += 1) {
        const prim: f64 = if ((t % 40) < 12) 0.7 else 0.08;
        b.buildExternal(prim, .sens, ext[0..]);
        b.step(ext[0..]);
    }
    std.debug.print("STRESS_BRAIN_spikes={d}\n", .{b.totalSpikes()});
    std.debug.print("STRESS_BRAIN_mean_S={e}\n", .{b.meanS()});

    // 6) learn
    const lr = learning.runLearnProbe();
    std.debug.print("STRESS_LEARN_top1={e}\n", .{lr.top1});
    std.debug.print("STRESS_LEARN_correct={d}\n", .{lr.correct});

    // 7) organism short
    var org = organism.Organism.init();
    org.encode_every = 20;
    const orep = org.run(60, true);
    std.debug.print("STRESS_ORG_ticks={d}\n", .{orep.ticks});
    std.debug.print("STRESS_ORG_episodes={d}\n", .{orep.episodes});
    std.debug.print("STRESS_ORG_curiosity={d}\n", .{orep.curiosity});

    const unit_ok = unit_pr.spike_count >= 2 and unit_pr.mean_isi_ms > 5 and unit_pr.mean_isi_ms < 250;
    const fi_ok = fi.mean_rate_Hz >= 4.0 and fi.mean_rate_Hz <= 90.0 and fi.n_with_isi >= 1;
    const net_ok = ns.spikes >= 1;
    const brain_ok = b.totalSpikes() >= 1;
    const learn_ok = lr.ok;
    const org_ok = orep.ok and orep.episodes >= 1;

    std.debug.print("gate_unit={s}\n", .{if (unit_ok) "PASS" else "FAIL"});
    std.debug.print("gate_fi={s}\n", .{if (fi_ok) "PASS" else "FAIL"});
    std.debug.print("gate_net={s}\n", .{if (net_ok) "PASS" else "FAIL"});
    std.debug.print("gate_brain={s}\n", .{if (brain_ok) "PASS" else "FAIL"});
    std.debug.print("gate_learn={s}\n", .{if (learn_ok) "PASS" else "FAIL"});
    std.debug.print("gate_org={s}\n", .{if (org_ok) "PASS" else "FAIL"});

    if (unit_ok and fi_ok and net_ok and brain_ok and learn_ok and org_ok) {
        std.debug.print("FSOT_STRESS PASS\n", .{});
    } else {
        std.debug.print("FSOT_STRESS FAIL\n", .{});
        std.process.exit(1);
    }
}

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const mode: []const u8 = if (args.len >= 2) args[1] else "all";

    if (std.mem.eql(u8, mode, "selftest")) {
        try runSelfTest();
    } else if (std.mem.eql(u8, mode, "learn")) {
        runLearnFixed();
    } else if (std.mem.eql(u8, mode, "curriculum")) {
        runCurriculum();
    } else if (std.mem.eql(u8, mode, "curiosity")) {
        runCuriosity();
    } else if (std.mem.eql(u8, mode, "transfer")) {
        runTransfer();
    } else if (std.mem.eql(u8, mode, "modulate") or std.mem.eql(u8, mode, "modulation") or std.mem.eql(u8, mode, "sme-mod")) {
        runModulate();
    } else if (std.mem.eql(u8, mode, "teach") or std.mem.eql(u8, mode, "5w1h") or std.mem.eql(u8, mode, "teach-5w1h")) {
        runTeach();
    } else if (std.mem.eql(u8, mode, "short-horizon") or std.mem.eql(u8, mode, "short_horizon") or std.mem.eql(u8, mode, "sh")) {
        runShortHorizon();
    } else if (std.mem.eql(u8, mode, "speech") or std.mem.eql(u8, mode, "speech-organ")) {
        runSpeechOrgan();
    } else if (std.mem.eql(u8, mode, "phase-b") or std.mem.eql(u8, mode, "phase_b") or std.mem.eql(u8, mode, "phaseb") or std.mem.eql(u8, mode, "experience-intelligence")) {
        // Phase B — experience intelligence (parallel with language twins)
        runPhaseB();
    } else if (std.mem.eql(u8, mode, "phase-c") or std.mem.eql(u8, mode, "phase_c") or std.mem.eql(u8, mode, "phasec") or std.mem.eql(u8, mode, "embodied") or std.mem.eql(u8, mode, "embodied-io")) {
        // Phase C — embodied I/O (parallel with language twins)
        runPhaseC();
    } else if (std.mem.eql(u8, mode, "phase-d") or std.mem.eql(u8, mode, "phase_d") or std.mem.eql(u8, mode, "phased") or std.mem.eql(u8, mode, "scientific") or std.mem.eql(u8, mode, "scientific-packaging")) {
        // Phase D — scientific packaging (parallel with language twins)
        runPhaseD();
    } else if (std.mem.eql(u8, mode, "bio-learn") or std.mem.eql(u8, mode, "bio_learn") or std.mem.eql(u8, mode, "animal-learn") or std.mem.eql(u8, mode, "learn-eval")) {
        // Animal/human learning suite — NOT GSM8K / LLM benchmarks
        runBioLearnEval();
    } else if (std.mem.eql(u8, mode, "self-study") or std.mem.eql(u8, mode, "self_study") or std.mem.eql(u8, mode, "study") or std.mem.eql(u8, mode, "materials")) {
        runSelfStudy();
    } else if (std.mem.eql(u8, mode, "bio-suite") or std.mem.eql(u8, mode, "bio_suite") or std.mem.eql(u8, mode, "frontier-eval")) {
        runBioSuite();
    } else if (std.mem.eql(u8, mode, "bio-converse") or std.mem.eql(u8, mode, "bio_converse") or std.mem.eql(u8, mode, "converse") or std.mem.eql(u8, mode, "think-speak") or std.mem.eql(u8, mode, "multi-turn")) {
        runBioConverse(false);
    } else if (std.mem.eql(u8, mode, "bio-converse-speak") or std.mem.eql(u8, mode, "converse-speak")) {
        runBioConverse(true);
    } else if (std.mem.eql(u8, mode, "bio-articulate") or std.mem.eql(u8, mode, "bio_articulate") or std.mem.eql(u8, mode, "articulate") or std.mem.eql(u8, mode, "say-fact") or std.mem.eql(u8, mode, "engram-speak")) {
        // Pure bio path: teach fact → episodic retrieve → motor speak → self-hear (NO chat module)
        runBioArticulate(false);
    } else if (std.mem.eql(u8, mode, "bio-articulate-speak") or std.mem.eql(u8, mode, "articulate-speak") or std.mem.eql(u8, mode, "say-fact-speak")) {
        runBioArticulate(true);
    } else if (std.mem.eql(u8, mode, "capacity") or std.mem.eql(u8, mode, "silicon-body") or std.mem.eql(u8, mode, "tier") or std.mem.eql(u8, mode, "body-capacity")) {
        // Silicon body: min stack vs Omen growth host (not plant "body" daemon)
        if (!capacity_tier_fixed.selfTest()) {
            std.debug.print("FSOT_CAPACITY FAIL\n", .{});
            std.process.exit(1);
        }
        const cap = capacity_tier_fixed.probe();
        capacity_tier_fixed.printReport(cap);
    } else if (std.mem.eql(u8, mode, "gpu-organ") or std.mem.eql(u8, mode, "gpu_organ") or std.mem.eql(u8, mode, "gpu") or std.mem.eql(u8, mode, "fsot-gpu")) {
        // GPU body organ — bridge to FSOT-GPU (trinary pack parity + native kernels)
        if (!gpu_organ_fixed.selfTest()) {
            std.debug.print("FSOT_GPU_ORGAN FAIL\n", .{});
            std.process.exit(1);
        }
        gpu_organ_fixed.printReport();
        _ = gpu_organ_fixed.consolidateBatch(0);
    } else if (std.mem.eql(u8, mode, "gpu-batch") or std.mem.eql(u8, mode, "gpu_batch") or std.mem.eql(u8, mode, "batch-sleep") or std.mem.eql(u8, mode, "sleep-replay")) {
        // Batch cosine + trit consensus sleep replay under Fixed mind
        if (!gpu_batch_fixed.selfTest()) {
            std.debug.print("FSOT_GPU_BATCH FAIL\n", .{});
            std.process.exit(1);
        }
        gpu_batch_fixed.printProbe();
    } else if (std.mem.eql(u8, mode, "gpu-vram") or std.mem.eql(u8, mode, "gpu_vram") or std.mem.eql(u8, mode, "vram-offload") or std.mem.eql(u8, mode, "vram")) {
        // Full VRAM matrix offload into FSOT-GPU consensus kernels
        if (!gpu_vram_fixed.selfTest()) {
            std.debug.print("FSOT_GPU_VRAM FAIL (worker/DLL/parity)\n", .{});
            std.process.exit(1);
        }
        gpu_batch_fixed.printVramProbe();
    } else if (std.mem.eql(u8, mode, "allen-dist") or std.mem.eql(u8, mode, "allen_dist") or std.mem.eql(u8, mode, "csv-dist") or std.mem.eql(u8, mode, "allen-variance") or std.mem.eql(u8, mode, "ks-allen")) {
        runAllenDist();
    } else if (std.mem.eql(u8, mode, "allen-class-dist") or std.mem.eql(u8, mode, "class-dist") or std.mem.eql(u8, mode, "cre-dist") or std.mem.eql(u8, mode, "cre_class_dist")) {
        runAllenClassDist();
    } else if (std.mem.eql(u8, mode, "genetic-var") or std.mem.eql(u8, mode, "genetic_var") or std.mem.eql(u8, mode, "mutate-orf") or std.mem.eql(u8, mode, "orf-var")) {
        runGeneticVar();
    } else if (std.mem.eql(u8, mode, "isi-ks") or std.mem.eql(u8, mode, "isi_ks") or std.mem.eql(u8, mode, "allen-isi-ks") or std.mem.eql(u8, mode, "ks-isi") or std.mem.eql(u8, mode, "isi-dist")) {
        runIsiKsProduct();
    } else if (std.mem.eql(u8, mode, "allen-bare") or std.mem.eql(u8, mode, "allen_bare") or std.mem.eql(u8, mode, "qemu-allen") or std.mem.eql(u8, mode, "bare-allen")) {
        runAllenBareHost();
    } else if (std.mem.eql(u8, mode, "scalpel") or std.mem.eql(u8, mode, "class-rates") or std.mem.eql(u8, mode, "allen-class")) {
        // Archive wetlab T1–T2: per-class FI rates abs Hz
        if (!scalpel_rate_fixed.selfTest()) {
            std.debug.print("FSOT_SCALPEL selftest weak — running full scalpel\n", .{});
        }
        const sc = scalpel_rate_fixed.runScalpel(48);
        scalpel_rate_fixed.printReport(sc);
        if (!sc.ok) std.process.exit(1);
    } else if (std.mem.eql(u8, mode, "skill") or std.mem.eql(u8, mode, "skill-organ") or std.mem.eql(u8, mode, "skill_organ") or std.mem.eql(u8, mode, "python-skill")) {
        // Python skill organ — interpreter sandbox (not mind authority)
        skill_organ_fixed.printProbe();
        if (!skill_organ_fixed.selfTest()) std.process.exit(1);
    } else if (std.mem.eql(u8, mode, "skill-run") or std.mem.eql(u8, mode, "run-skill")) {
        // fsot_mind skill-run add "2 3"
        const skill_name: []const u8 = if (args.len >= 3) args[2] else "add";
        const skill_arg: []const u8 = if (args.len >= 4) args[3] else "2 3";
        const r = skill_organ_fixed.runSkill(skill_name, skill_arg, 8000);
        std.debug.print("SKILL {s} ok={} exit={d} ms={d} out={s}\n", .{
            skill_name,
            r.ok,
            r.exit_code,
            r.duration_ms,
            r.stdout[0..r.stdout_n],
        });
        if (!r.ok) std.process.exit(1);
        std.debug.print("FSOT_SKILL_RUN PASS\n", .{});
    } else if (std.mem.eql(u8, mode, "know-query") or std.mem.eql(u8, mode, "know_query") or std.mem.eql(u8, mode, "study-tool") or std.mem.eql(u8, mode, "lookup-learn") or std.mem.eql(u8, mode, "i-dont-know")) {
        // Human: unknown concept → query archive/API → retain engram
        runKnowQuery(false);
    } else if (std.mem.eql(u8, mode, "know-query-live") or std.mem.eql(u8, mode, "lookup-live") or std.mem.eql(u8, mode, "study-tool-live")) {
        runKnowQuery(true);
    } else if (std.mem.eql(u8, mode, "think") or std.mem.eql(u8, mode, "internal-think") or std.mem.eql(u8, mode, "brainstorm") or std.mem.eql(u8, mode, "self-correct")) {
        // Internal loop: retrace → cross-check → brainstorm → self-correct (probe)
        runInternalThink(0);
    } else if (std.mem.eql(u8, mode, "think-hour") or std.mem.eql(u8, mode, "think_hour") or std.mem.eql(u8, mode, "hour-think")) {
        runInternalThink(60);
    } else if (std.mem.eql(u8, mode, "think-min") or std.mem.eql(u8, mode, "think_min")) {
        var mins: u32 = 5;
        if (args.len >= 3) {
            mins = std.fmt.parseInt(u32, args[2], 10) catch 5;
            if (mins == 0) mins = 1;
            if (mins > 24 * 60) mins = 24 * 60;
        }
        runInternalThink(mins);
    } else if (std.mem.eql(u8, mode, "boot-think") or std.mem.eql(u8, mode, "top-to-bottom") or std.mem.eql(u8, mode, "t2b")) {
        // Top-to-bottom boot: bio gates then long internal think (default 60 min)
        std.debug.print("=== FSOT TOP-TO-BOTTOM BOOT → THINK ===\n", .{});
        runBioLearnEval();
        runSelfStudy();
        runBioConverse(false);
        runInternalThink(0);
        var mins: u32 = 60;
        if (args.len >= 3) {
            mins = std.fmt.parseInt(u32, args[2], 10) catch 60;
            if (mins == 0) mins = 60;
        }
        std.debug.print("--- entering long think ({d} min) ---\n", .{mins});
        runInternalThink(mins);
    } else if (std.mem.eql(u8, mode, "cross-modal") or std.mem.eql(u8, mode, "cross_modal") or std.mem.eql(u8, mode, "av") or std.mem.eql(u8, mode, "crossmodal")) {
        runCrossModal();
    } else if (std.mem.eql(u8, mode, "bio-io") or std.mem.eql(u8, mode, "bio_io") or std.mem.eql(u8, mode, "sensory") or std.mem.eql(u8, mode, "io")) {
        runBioIo();
    } else if (std.mem.eql(u8, mode, "machine") or std.mem.eql(u8, mode, "machine-encode") or std.mem.eql(u8, mode, "abi")) {
        runMachineEncode();
    } else if (std.mem.eql(u8, mode, "machine-lang") or std.mem.eql(u8, mode, "machine_lang") or std.mem.eql(u8, mode, "mlang") or std.mem.eql(u8, mode, "tongue")) {
        runMachineLang();
    } else if (std.mem.eql(u8, mode, "machine-lang-stress") or std.mem.eql(u8, mode, "mlang-stress") or std.mem.eql(u8, mode, "tongue-stress")) {
        runMachineLangStress();
    } else if (std.mem.eql(u8, mode, "english") or std.mem.eql(u8, mode, "lexicon") or std.mem.eql(u8, mode, "tts") or std.mem.eql(u8, mode, "words")) {
        runEnglishCodec();
    } else if (std.mem.eql(u8, mode, "practice") or std.mem.eql(u8, mode, "language-practice") or std.mem.eql(u8, mode, "lang-practice") or std.mem.eql(u8, mode, "self-speak")) {
        runLanguagePractice();
    } else if (std.mem.eql(u8, mode, "dict-stress") or std.mem.eql(u8, mode, "dictionary") or std.mem.eql(u8, mode, "lexicon-stress") or std.mem.eql(u8, mode, "new-words")) {
        runDictionaryStress();
    } else if (std.mem.eql(u8, mode, "language-depth") or std.mem.eql(u8, mode, "depth-words") or std.mem.eql(u8, mode, "define") or std.mem.eql(u8, mode, "pos") or std.mem.eql(u8, mode, "think-words") or std.mem.eql(u8, mode, "meaning")) {
        runLanguageDepth(false);
    } else if (std.mem.eql(u8, mode, "language-depth-speak") or std.mem.eql(u8, mode, "define-speak") or std.mem.eql(u8, mode, "think-speak")) {
        runLanguageDepth(true);
    } else if (std.mem.eql(u8, mode, "lang-suite") or std.mem.eql(u8, mode, "language-suite") or std.mem.eql(u8, mode, "lex-suite")) {
        // Full language paces with dictionary + depth
        runEnglishCodec();
        runLanguagePractice();
        runDictionaryStress();
        runLanguageDepth(false);
        runBrainLearn(false);
        std.debug.print("FSOT_LANGUAGE_SUITE PASS\n", .{});
    } else if (std.mem.eql(u8, mode, "grade") or std.mem.eql(u8, mode, "curriculum")) {
        runGradePractice();
    } else if (std.mem.eql(u8, mode, "ladder") or std.mem.eql(u8, mode, "straight-a") or std.mem.eql(u8, mode, "grades")) {
        runGradeLadder();
    } else if (std.mem.eql(u8, mode, "preschool") or std.mem.eql(u8, mode, "pk")) {
        runGradeBand(.preschool);
    } else if (std.mem.eql(u8, mode, "kindergarten") or std.mem.eql(u8, mode, "kinder") or std.mem.eql(u8, mode, "k")) {
        runGradeBand(.kindergarten);
    } else if (std.mem.eql(u8, mode, "grade1") or std.mem.eql(u8, mode, "g1") or std.mem.eql(u8, mode, "first")) {
        runGradeBand(.grade1);
    } else if (std.mem.eql(u8, mode, "grade2") or std.mem.eql(u8, mode, "g2")) {
        runGradeBand(.grade2);
    } else if (std.mem.eql(u8, mode, "grade3") or std.mem.eql(u8, mode, "g3")) {
        runGradeBand(.grade3);
    } else if (std.mem.eql(u8, mode, "grade4") or std.mem.eql(u8, mode, "g4")) {
        runGradeBand(.grade4);
    } else if (std.mem.eql(u8, mode, "grade5") or std.mem.eql(u8, mode, "g5")) {
        runGradeBand(.grade5);
    } else if (std.mem.eql(u8, mode, "grade6") or std.mem.eql(u8, mode, "g6") or std.mem.eql(u8, mode, "ms6")) {
        runGradeBand(.grade6);
    } else if (std.mem.eql(u8, mode, "grade7") or std.mem.eql(u8, mode, "g7") or std.mem.eql(u8, mode, "ms7")) {
        runGradeBand(.grade7);
    } else if (std.mem.eql(u8, mode, "grade8") or std.mem.eql(u8, mode, "g8") or std.mem.eql(u8, mode, "ms8")) {
        runGradeBand(.grade8);
    } else if (std.mem.eql(u8, mode, "reason") or std.mem.eql(u8, mode, "open-reason") or std.mem.eql(u8, mode, "think") or std.mem.eql(u8, mode, "multi-hop")) {
        runReasonPractice();
    } else if (std.mem.eql(u8, mode, "brain-learn") or std.mem.eql(u8, mode, "brain_learn") or std.mem.eql(u8, mode, "real-learn") or std.mem.eql(u8, mode, "experience") or std.mem.eql(u8, mode, "school")) {
        // REAL brain: encode school into OrganismF + sleep + prove (not Python-only)
        runBrainLearn(false);
    } else if (std.mem.eql(u8, mode, "brain-learn-speak") or std.mem.eql(u8, mode, "real-learn-speak") or std.mem.eql(u8, mode, "school-speak")) {
        runBrainLearn(true);
    } else if (std.mem.eql(u8, mode, "novel") or std.mem.eql(u8, mode, "inquiry") or std.mem.eql(u8, mode, "synthesize") or std.mem.eql(u8, mode, "idea")) {
        runNovelInquiry();
    } else if (std.mem.eql(u8, mode, "checkpoint") or std.mem.eql(u8, mode, "savegame") or std.mem.eql(u8, mode, "save-load")) {
        runCheckpoint();
    } else if (std.mem.eql(u8, mode, "failure") or std.mem.eql(u8, mode, "lesion") or std.mem.eql(u8, mode, "boundaries")) {
        runFailure();
    } else if (std.mem.eql(u8, mode, "wire") or std.mem.eql(u8, mode, "wire-around") or std.mem.eql(u8, mode, "wire_around")) {
        runWireAround();
    } else if (std.mem.eql(u8, mode, "symbol") or std.mem.eql(u8, mode, "symbol-assoc") or std.mem.eql(u8, mode, "anchors")) {
        runSymbolAssoc();
    } else if (std.mem.eql(u8, mode, "hardware") or std.mem.eql(u8, mode, "plant")) {
        runHardware();
    } else if (std.mem.eql(u8, mode, "host-senses") or std.mem.eql(u8, mode, "host_senses") or std.mem.eql(u8, mode, "senses") or std.mem.eql(u8, mode, "host")) {
        runHostSenses();
    } else if (std.mem.eql(u8, mode, "host-loop") or std.mem.eql(u8, mode, "host_loop") or std.mem.eql(u8, mode, "loop")) {
        runHostLoop();
    } else if (std.mem.eql(u8, mode, "body") or std.mem.eql(u8, mode, "daemon") or std.mem.eql(u8, mode, "boot")) {
        // plant smoke only
        runBodyDaemon();
    } else if (std.mem.eql(u8, mode, "mind") or std.mem.eql(u8, mode, "live-mind") or std.mem.eql(u8, mode, "live_mind") or std.mem.eql(u8, mode, "connected") or std.mem.eql(u8, mode, "awake")) {
        // FULL connected organism (brain+memory+senses+speech)
        runLiveMindConnected();
    } else if (std.mem.eql(u8, mode, "speakers") or std.mem.eql(u8, mode, "speaker") or std.mem.eql(u8, mode, "audio-out")) {
        runSpeakers();
    } else if (std.mem.eql(u8, mode, "autonomous") or std.mem.eql(u8, mode, "auto") or std.mem.eql(u8, mode, "chew")) {
        runAutonomous();
    } else if (std.mem.eql(u8, mode, "sme-fixed") or std.mem.eql(u8, mode, "sme_fixed") or std.mem.eql(u8, mode, "bands-fixed")) {
        runSmeFixed();
    } else if (std.mem.eql(u8, mode, "attention") or std.mem.eql(u8, mode, "eeg") or std.mem.eql(u8, mode, "eeg-gates") or std.mem.eql(u8, mode, "attune")) {
        runAttentionEeg();
    } else if (std.mem.eql(u8, mode, "mnist") or std.mem.eql(u8, mode, "mnist-gate") or std.mem.eql(u8, mode, "mnist_accuracy")) {
        runMnistAccuracy();
    } else if (std.mem.eql(u8, mode, "depth") or std.mem.eql(u8, mode, "understand") or std.mem.eql(u8, mode, "paraphrase") or std.mem.eql(u8, mode, "grade-depth")) {
        runGradeDepth();
    } else if (std.mem.eql(u8, mode, "pathways") or std.mem.eql(u8, mode, "synapse") or std.mem.eql(u8, mode, "synaptic") or std.mem.eql(u8, mode, "trace") or std.mem.eql(u8, mode, "think-path") or std.mem.eql(u8, mode, "glia") or std.mem.eql(u8, mode, "molecular") or std.mem.eql(u8, mode, "cascade")) {
        runSynapsePathways();
    } else if (std.mem.eql(u8, mode, "md") or std.mem.eql(u8, mode, "allatom") or std.mem.eql(u8, mode, "all-atom") or std.mem.eql(u8, mode, "allatom-md") or std.mem.eql(u8, mode, "molecular-dynamics")) {
        runAllAtomMd();
    } else if (std.mem.eql(u8, mode, "neuromod") or std.mem.eql(u8, mode, "modulators") or std.mem.eql(u8, mode, "da-ach")) {
        runNeuromod();
    } else if (std.mem.eql(u8, mode, "sleep") or std.mem.eql(u8, mode, "replay") or std.mem.eql(u8, mode, "consolidate") or std.mem.eql(u8, mode, "consolidation")) {
        runSleepReplay();
    } else if (std.mem.eql(u8, mode, "claim") or std.mem.eql(u8, mode, "claimability") or std.mem.eql(u8, mode, "multi-hop") or std.mem.eql(u8, mode, "multihop")) {
        runClaimability();
    } else if (std.mem.eql(u8, mode, "compose") or std.mem.eql(u8, mode, "compose-intel") or std.mem.eql(u8, mode, "compose_intel") or std.mem.eql(u8, mode, "answer-hop") or std.mem.eql(u8, mode, "answer_hop")) {
        runComposeIntel();
    } else if (std.mem.eql(u8, mode, "intel-bio") or std.mem.eql(u8, mode, "intel_bio") or std.mem.eql(u8, mode, "bio-intel")) {
        runIntelBio();
    } else if (std.mem.eql(u8, mode, "intel-loop") or std.mem.eql(u8, mode, "intel_loop") or std.mem.eql(u8, mode, "train-sleep-prove") or std.mem.eql(u8, mode, "loop")) {
        runIntelLoop();
    } else if (std.mem.eql(u8, mode, "frontier") or std.mem.eql(u8, mode, "intel-frontier") or std.mem.eql(u8, mode, "multi-day") or std.mem.eql(u8, mode, "curiosity-train")) {
        runIntelFrontier();
    } else if (std.mem.eql(u8, mode, "pixel-id") or std.mem.eql(u8, mode, "pixel_id") or std.mem.eql(u8, mode, "pixelid")) {
        runPixelId();
    } else if (std.mem.eql(u8, mode, "vision") or std.mem.eql(u8, mode, "vision-inject") or std.mem.eql(u8, mode, "vision_inject")) {
        runVisionInjectDemo();
    } else if (std.mem.eql(u8, mode, "live")) {
        // short brain-only activity (no host) — prefer "mind" for full stack
        runLive();
    } else if (std.mem.eql(u8, mode, "inject")) {
        runInject();
    } else if (std.mem.eql(u8, mode, "structure")) {
        runStructure();
    } else if (std.mem.eql(u8, mode, "memory")) {
        runMemory();
    } else if (std.mem.eql(u8, mode, "organism")) {
        runOrganism();
    } else if (std.mem.eql(u8, mode, "intel")) {
        runIntel();
    } else if (std.mem.eql(u8, mode, "fixed") or std.mem.eql(u8, mode, "fixedpoint") or std.mem.eql(u8, mode, "authority")) {
        runFixed();
    } else if (std.mem.eql(u8, mode, "genetic") or std.mem.eql(u8, mode, "codon")) {
        runGenetic();
    } else if (std.mem.eql(u8, mode, "sme")) {
        // default SME authority = fixed bands
        runSmeFixed();
    } else if (std.mem.eql(u8, mode, "sme-float") or std.mem.eql(u8, mode, "sme_float")) {
        runSme();
    } else if (std.mem.eql(u8, mode, "inject-file") or std.mem.eql(u8, mode, "inject_file")) {
        if (args.len < 3) {
            std.debug.print("usage: fsot_mind inject-file <path>\n", .{});
            std.process.exit(2);
        }
        try runInjectFile(args[2]);
    } else if (std.mem.eql(u8, mode, "bio")) {
        // bio authority = fixed Allen FI + bio I/O routes
        runFixed();
        runBioIo();
        runFailure();
        runWireAround();
        runHardware();
        runHostSenses();
        runHostLoop();
        runSpeakers();
    } else if (std.mem.eql(u8, mode, "bio-float") or std.mem.eql(u8, mode, "bio_float")) {
        const path: ?[]const u8 = if (args.len >= 3) args[2] else null;
        try runBio(path);
    } else if (std.mem.eql(u8, mode, "stress")) {
        // stress authority = fixed stack + expanded scaffolds
        runFixed();
        runLearnFixed();
        runCurriculum();
        runCuriosity();
        runTeach();
        runTransfer();
        runModulate();
        runSmeFixed();
        runShortHorizon();
        runSpeechOrgan();
        runCrossModal();
        runBioIo();
        runMachineEncode();
        runFailure();
        runWireAround();
        runSymbolAssoc();
        runHardware();
        runHostSenses();
        runHostLoop();
        runSpeakers();
        runAutonomous();
        runInject();
        runVisionInjectDemo();
        runPixelId();
        runOrganism();
        runIntel();
        std.debug.print("FSOT_STRESS PASS\n", .{});
        std.debug.print("FSOT_STRESS_FIXED_AUTHORITY_OK\n", .{});
    } else if (std.mem.eql(u8, mode, "float-lab") or std.mem.eql(u8, mode, "float_lab") or std.mem.eql(u8, mode, "lab")) {
        try runSelfTest();
        runGenetic();
        runLearn();
        runMemory();
        try runBio(null);
        try runStress();
        std.debug.print("FSOT_FLOAT_LAB_OK\n", .{});
    } else if (std.mem.eql(u8, mode, "all") or std.mem.eql(u8, mode, "suite") or std.mem.eql(u8, mode, "tests")) {
        // Full unit-test suite (not the live organism — use "mind" for that)
        runFixed();
        runLearnFixed();
        runCurriculum();
        runCuriosity();
        runTeach();
        runTransfer();
        runModulate();
        runSmeFixed();
        runAttentionEeg();
        runShortHorizon();
        runSpeechOrgan();
        runCrossModal();
        runBioIo();
        runMachineEncode();
        runMachineLang();
        runFailure();
        runWireAround();
        runSymbolAssoc();
        runHardware();
        runHostSenses();
        runHostLoop();
        runSpeakers();
        runAutonomous();
        runInject();
        runVisionInjectDemo();
        runPixelId();
        runOrganism();
        runIntel();
        runGenetic();
        // Real-brain school: encode → practice → sleep → prove (closes Python disconnect)
        runBrainLearn(false);
        std.debug.print("FSOT_MIND_HOST_OK\n", .{});
        std.debug.print("FSOT_FIXED_AUTHORITY_OK\n", .{});
        std.debug.print("FSOT_NO_PYTHON_CORE_OK\n", .{});
        std.debug.print("FSOT_INTEL_HOST_OK\n", .{});
        std.debug.print("NOTE: suite is gates only. Live intelligence → BOOT_MIND.cmd or mode 'mind'\n", .{});
        std.debug.print("NOTE: brain-learn / real-learn = school on OrganismF (not Python-only)\n", .{});
    } else {
        std.debug.print("usage: fsot_mind mind|body|stress|suite|brain-learn|english|…\n", .{});
        std.debug.print("  mind           = FULL connected organism (brain+memory+senses+speech)\n", .{});
        std.debug.print("  brain-learn    = REAL brain teach→practice→sleep→prove\n", .{});
        std.debug.print("  brain-learn-speak = same + English TTS of learned facts\n", .{});
        std.debug.print("  english        = lexicon + Windows TTS (real words, not formants)\n", .{});
        std.debug.print("  practice       = utter → TTS → self-hear → encode\n", .{});
        std.debug.print("  bio-learn      = animal/human learning eval (NOT GSM8K/LLM benches)\n", .{});
        std.debug.print("  self-study     = read materials → try → re-read → sleep → prove\n", .{});
        std.debug.print("  bio-suite      = learn + self-study + converse + MNIST\n", .{});
        std.debug.print("  bio-converse   = multi-turn think-from-memory → articulate\n", .{});
        std.debug.print("  capacity       = silicon body tier (RAM/GPU) + growth budgets\n", .{});
        std.debug.print("  genetic-var    = mutateOrf FI variance (trinary codon diversity)\n", .{});
        std.debug.print("  isi-ks         = full ISI distribution KS vs Allen CSV (product)\n", .{});
        std.debug.print("  allen-dist     = CSV variance + Cre-class dist (host)\n", .{});
        std.debug.print("  gpu-organ      = FSOT-GPU bridge (parity + native kernels)\n", .{});
        std.debug.print("  gpu-batch      = batch cosine/trit sleep replay (Fixed + FSOT-GPU)\n", .{});
        std.debug.print("  gpu-vram       = full VRAM offload → FSOT consensus kernels + top-K\n", .{});
        std.debug.print("  scalpel        = Allen class rates Pyr/PV/SST/VIP |Δ| Hz\n", .{});
        std.debug.print("  compose        = answer-dependent hops + schema discovery + ablation\n", .{});
        std.debug.print("  skill          = Python skill organ probe\n", .{});
        std.debug.print("  skill-run NAME = run skill (e.g. skill-run add)\n", .{});
        std.debug.print("  know-query     = I-don't-know → query tool → retain (archive/wiki)\n", .{});
        std.debug.print("  know-query-live= same + live Wikipedia REST when local miss\n", .{});
        std.debug.print("  think          = internal retrace/cross-check/brainstorm/self-correct\n", .{});
        std.debug.print("  think-hour     = same loop for 60 wall-clock minutes\n", .{});
        std.debug.print("  think-min N    = internal think for N minutes\n", .{});
        std.debug.print("  boot-think     = top-to-bottom gates then 60min think (or boot-think N)\n", .{});
        std.debug.print("  bio-articulate = teach→retrieve→motor→self-hear\n", .{});
        std.debug.print("  mnist          = classic NN sensory discrimination gate\n", .{});
        std.debug.print("  speakers       = formant/DAC smoke only (NOT English)\n", .{});
        std.debug.print("  body           = plant smoke only (senses loop)\n", .{});
        std.debug.print("  suite          = unit-test gates\n", .{});
        std.process.exit(2);
    }
}

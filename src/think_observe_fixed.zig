//! Observation logs for long think runs — genetics, mutations, learn vs accuracy.
//!
//! Files under data/results/:
//!   THINK_GENETIC.log     — DNA/genotype structure + mutation events
//!   THINK_ACCURACY.jsonl  — capacity vs hit rates over time
//!
//! Not LLM telemetry. Biological / structural truth of the Fixed lattice.

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const network_f = @import("network_fixed.zig");
const genotype_f = @import("genotype_fixed.zig");
const cell_types = @import("cell_types.zig");
const Fixed = fixed.Fixed;

pub const Observe = struct {
    genetic: ?std.fs.File = null,
    accuracy: ?std.fs.File = null,
    last_w_fp: u64 = 0,
    last_spin_fp: u64 = 0,
    n_mutations_logged: u32 = 0,
    baseline_n_syn: u32 = 0,

    pub fn open() Observe {
        std.fs.cwd().makePath("data/results") catch {};
        var o: Observe = .{};
        o.genetic = std.fs.cwd().createFile("data/results/THINK_GENETIC.log", .{}) catch null;
        o.accuracy = std.fs.cwd().createFile("data/results/THINK_ACCURACY.jsonl", .{}) catch null;
        return o;
    }

    pub fn close(self: *Observe) void {
        if (self.genetic) |f| f.close();
        if (self.accuracy) |f| f.close();
        self.genetic = null;
        self.accuracy = null;
    }

    fn gprint(self: *Observe, comptime fmt: []const u8, args: anytype) void {
        if (self.genetic) |f| {
            var buf: [512]u8 = undefined;
            const line = std.fmt.bufPrint(buf[0..], fmt, args) catch return;
            f.writeAll(line) catch {};
            f.sync() catch {};
        }
        // also stderr for visibility
        std.debug.print(fmt, args);
    }

    /// Full genotype dump at boot (DNA structure of the lattice).
    pub fn logGenomeBoot(self: *Observe, b: *const brain_f.BrainF) void {
        const st = b.structureReport();
        self.baseline_n_syn = st.n_synapses;
        self.last_w_fp = weightFingerprint(b);
        self.last_spin_fp = spinFingerprint(b);
        self.gprint("=== GENETIC DNA STRUCTURE (boot) seed={d} n={d} n_syn={d} pyr={d} i={d} ===\n", .{
            b.seed,
            b.n,
            st.n_synapses,
            st.n_pyr,
            st.n_i,
        });
        self.gprint("w_fp={x} spin_fp={x}\n", .{ self.last_w_fp, self.last_spin_fp });
        var u: usize = 0;
        while (u < b.n) : (u += 1) {
            const g = b.genotypes[u];
            const spin_f = fixed.toF64(g.composite_spin);
            const chg_f = fixed.toF64(g.composite_charge);
            const thr_f = fixed.toF64(g.phenotype.fire_threshold);
            self.gprint(
                "UNIT {d} reg={s} ct={s} sign={d} spin={e} charge={e} thr={e} genes=",
                .{
                    g.unit_id,
                    regName(b.region_of[u]),
                    ctName(g.cell_type),
                    g.synapse_sign,
                    spin_f,
                    chg_f,
                    thr_f,
                },
            );
            var gi: usize = 0;
            while (gi < 4) : (gi += 1) {
                const gp = g.genes[gi];
                const ename = switch (gp.name) {
                    .scn => "SCN",
                    .kcn => "KCN",
                    .cacna => "CACNA",
                    .leak => "LEAK",
                };
                self.gprint("{s}:codons={d},expr={e} ", .{ ename, gp.n_codons, fixed.toF64(gp.expression) });
            }
            self.gprint("\n", .{});
        }
        self.gprint("=== END GENOME BOOT ===\n", .{});
    }

    /// Compare W / spin fingerprints; log mutation/plasticity events.
    pub fn maybeLogMutation(self: *Observe, b: *const brain_f.BrainF, cycle: u32) void {
        const wfp = weightFingerprint(b);
        const sfp = spinFingerprint(b);
        const st = b.structureReport();
        if (wfp != self.last_w_fp or sfp != self.last_spin_fp or st.n_synapses != self.baseline_n_syn) {
            self.n_mutations_logged += 1;
            self.gprint(
                "MUTATION t_cycle={d} id={d} w_fp {x}->{x} spin_fp {x}->{x} n_syn {d}->{d} (plasticity/rewire)\n",
                .{
                    cycle,
                    self.n_mutations_logged,
                    self.last_w_fp,
                    wfp,
                    self.last_spin_fp,
                    sfp,
                    self.baseline_n_syn,
                    st.n_synapses,
                },
            );
            self.last_w_fp = wfp;
            self.last_spin_fp = sfp;
            self.baseline_n_syn = st.n_synapses;
        }
    }

    /// Bio metrics JSONL — episodic recall, curiosity hits, STM/LTM, sleep, neuromod.
    /// NOT LLM benchmarks (no GSM8K / next-token).
    pub fn logAccuracy(
        self: *Observe,
        cycle: u32,
        elapsed_ms: u64,
        retrace_ok: u32,
        retrace_n: u32,
        disc_hit: u32,
        disc_n: u32,
        pending: u32,
        new_concepts: u32,
        uniq_ideas: u32,
        grown: u32,
        grown_cap: u32,
        eng: u32,
        eng_cap: u32,
        eps: u32,
        eps_cap: u32,
        spikes: u32,
        n_syn: u32,
    ) void {
        logAccuracyBio(self, cycle, elapsed_ms, retrace_ok, retrace_n, disc_hit, disc_n, pending, new_concepts, uniq_ideas, grown, grown_cap, eng, eng_cap, eps, eps_cap, spikes, n_syn, 0, 0, 0, 0, 0, 0, 0);
    }

    pub fn logAccuracyBio(
        self: *Observe,
        cycle: u32,
        elapsed_ms: u64,
        retrace_ok: u32,
        retrace_n: u32,
        disc_hit: u32,
        disc_n: u32,
        pending: u32,
        new_concepts: u32,
        uniq_ideas: u32,
        stm_grown: u32,
        stm_grown_cap: u32,
        eng: u32,
        eng_cap: u32,
        eps: u32,
        eps_cap: u32,
        spikes: u32,
        n_syn: u32,
        life_grown: u32,
        ltm_spill: u32,
        n_sleep: u32,
        batch_replay: u32,
        mean_da: f64,
        mean_ach: f64,
        mean_batch_cos: f64,
    ) void {
        const f = self.accuracy orelse return;
        // episodic_retrace = encode→retrieve fidelity (not chat accuracy)
        const episodic_retrace: f64 = if (retrace_n > 0) @as(f64, @floatFromInt(retrace_ok)) / @as(f64, @floatFromInt(retrace_n)) else 0;
        // curiosity_hit = unknown-word lookup that retained (discover organ)
        const curiosity_hit: f64 = if (disc_n > 0) @as(f64, @floatFromInt(disc_hit)) / @as(f64, @floatFromInt(disc_n)) else 0;
        const stm_fill: f64 = if (stm_grown_cap > 0) @as(f64, @floatFromInt(stm_grown)) / @as(f64, @floatFromInt(stm_grown_cap)) else 0;
        var buf: [768]u8 = undefined;
        const line = std.fmt.bufPrint(buf[0..],
            "{{\"cycle\":{d},\"ms\":{d},\"metric_kind\":\"bio_episodic_not_llm\",\"episodic_retrace\":{e},\"curiosity_hit\":{e},\"pending_open\":{d},\"new_concepts\":{d},\"uniq_ideas\":{d},\"stm_grown\":{d},\"stm_grown_cap\":{d},\"stm_fill\":{e},\"life_grown\":{d},\"ltm_spill\":{d},\"eng\":{d},\"eng_cap\":{d},\"eps\":{d},\"eps_cap\":{d},\"spikes\":{d},\"n_syn\":{d},\"n_sleep\":{d},\"batch_replay\":{d},\"mean_da\":{e},\"mean_ach\":{e},\"mean_batch_cos\":{e},\"retrace_acc\":{e},\"discover_acc\":{e}}}\n",
            .{
                cycle,
                elapsed_ms,
                episodic_retrace,
                curiosity_hit,
                pending,
                new_concepts,
                uniq_ideas,
                stm_grown,
                stm_grown_cap,
                stm_fill,
                life_grown,
                ltm_spill,
                eng,
                eng_cap,
                eps,
                eps_cap,
                spikes,
                n_syn,
                n_sleep,
                batch_replay,
                mean_da,
                mean_ach,
                mean_batch_cos,
                // aliases for older readers
                episodic_retrace,
                curiosity_hit,
            },
        ) catch return;
        f.writeAll(line) catch {};
        f.sync() catch {};
    }
};

fn ctName(ct: cell_types.CellType) []const u8 {
    return switch (ct) {
        .pyr => "pyr",
        .pv => "pv",
        .sst => "sst",
        .vip => "vip",
    };
}

fn regName(r: brain_f.RegionId) []const u8 {
    return switch (r) {
        .thal => "thal",
        .sens => "sens",
        .assoc => "assoc",
        .hipp => "hipp",
    };
}

fn weightFingerprint(b: *const brain_f.BrainF) u64 {
    var h: u64 = 14695981039346656037;
    var i: usize = 0;
    while (i < b.n) : (i += 1) {
        var j: usize = 0;
        while (j < b.n) : (j += 1) {
            const w = b.net.W[i * network_f.MAX_N + j];
            const bits: u64 = @bitCast(@as(i64, w));
            h ^= bits;
            h *%= 1099511628211;
        }
    }
    return h;
}

fn spinFingerprint(b: *const brain_f.BrainF) u64 {
    var h: u64 = 14695981039346656037;
    var i: usize = 0;
    while (i < b.n) : (i += 1) {
        const bits: u64 = @bitCast(@as(i64, b.genotypes[i].composite_spin));
        h ^= bits;
        h *%= 1099511628211;
        h ^= @as(u64, @intCast(@as(u8, @bitCast(b.genotypes[i].synapse_sign))));
        h *%= 1099511628211;
    }
    return h;
}

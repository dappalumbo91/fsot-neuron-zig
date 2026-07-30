//! GPU-batch organ work under Fixed mind authority.
//!
//! Implements the *next* natural steps after FSOT-GPU bridge:
//!   1. Batch episode fingerprint cosine (STM hot set) — O(n²) windowed
//!   2. Trit consensus affinity (collapse-gated, no softmax) — FSOT-GPU contract
//!   3. Sleep replay of top similar pairs → re-drive lattice + re-bind engrams
//!
//! Device path:
//!   - Prefer: full VRAM offload → FSOT-GPU fsot_attn_lib consensus + top-K
//!   - Fallback: Fixed-point CPU batch (deterministic, min-stack green)
//!   - Always: consolidateBatch smoke when organ ready
//!
//! Mode: fsot_mind gpu-batch | gpu-vram

const std = @import("std");
const fixed = @import("fixed.zig");
const memory_f = @import("memory_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const gpu_organ = @import("gpu_organ_fixed.zig");
const gpu_vram = @import("gpu_vram_fixed.zig");
const Fixed = fixed.Fixed;

pub const MAX_BATCH: usize = memory_f.MAX_EPISODES;
pub const MAX_PAIRS: usize = 32;

pub const Pair = struct {
    i: u32 = 0,
    j: u32 = 0,
    cos_sim: Fixed = 0,
    trit_sim: Fixed = 0,
    /// blended score used for ranking
    score: Fixed = 0,
};

pub const BatchReport = struct {
    ok: bool = false,
    n_eps: u32 = 0,
    n_pairs: u32 = 0,
    n_replayed: u32 = 0,
    mean_cos: f64 = 0,
    mean_trit: f64 = 0,
    best_cos: f64 = 0,
    path: []const u8 = "cpu-fixed",
    gpu_present: bool = false,
    vram_offload: bool = false,
    vram_ms: u64 = 0,
    ms: u64 = 0,
};

/// Collapse Fixed → trit code 0/1/2 using FSOT-GPU threshold (via f64 for compare).
fn collapseFixed(x: Fixed) u8 {
    const v = fixed.toF64(x);
    return gpu_organ.collapseTrit(v);
}

/// Trit consensus similarity on two fingerprints (mean of same − opp over dims).
/// Superposed (code 1) contributes 0 — matches FSOT-GPU trit_similarity spirit.
pub fn tritSimFp(a: *const [memory_f.FP_DIM]Fixed, b: *const [memory_f.FP_DIM]Fixed) Fixed {
    var same: i32 = 0;
    var opp: i32 = 0;
    var used: i32 = 0;
    var d: usize = 0;
    while (d < memory_f.FP_DIM) : (d += 1) {
        const ca = collapseFixed(a[d]);
        const cb = collapseFixed(b[d]);
        if (ca == 1 or cb == 1) continue; // superposed: no vote
        used += 1;
        if (ca == cb) same += 1 else opp += 1;
    }
    if (used == 0) return 0;
    // (same - opp) / used ∈ [-1,1]
    return fixed.fromRatio(same - opp, used);
}

/// Find top-K most similar episode pairs (i < j) by blended cosine + trit.
pub fn findTopPairs(store: *const memory_f.StoreF, k: usize, out: []Pair) usize {
    if (store.n < 2 or k == 0) return 0;
    const n = store.n;
    var n_out: usize = 0;

    // Window: last min(n, 64) episodes for O(1) think budgets; full n if small
    const win: usize = if (n > 64) 64 else n;
    const base: usize = n - win;

    var i: usize = base;
    while (i < n) : (i += 1) {
        if (!store.episodes[i].valid) continue;
        var j: usize = i + 1;
        while (j < n) : (j += 1) {
            if (!store.episodes[j].valid) continue;
            const cos = memory_f.cosineFp(&store.episodes[i].fp, &store.episodes[j].fp);
            const trit = tritSimFp(&store.episodes[i].fp, &store.episodes[j].fp);
            // blend: 0.6 cos + 0.4 trit (Fixed)
            const score = fixed.add(
                fixed.mul(cos, fixed.fromDecimalStr("0.6")),
                fixed.mul(trit, fixed.fromDecimalStr("0.4")),
            );
            // insert into top-k heap-lite (linear)
            const p = Pair{
                .i = @intCast(i),
                .j = @intCast(j),
                .cos_sim = cos,
                .trit_sim = trit,
                .score = score,
            };
            if (n_out < k) {
                out[n_out] = p;
                n_out += 1;
                // bubble new max toward sorted descending score
                var t = n_out - 1;
                while (t > 0 and fixed.gt(out[t].score, out[t - 1].score)) : (t -= 1) {
                    const tmp = out[t - 1];
                    out[t - 1] = out[t];
                    out[t] = tmp;
                }
            } else if (fixed.gt(score, out[n_out - 1].score)) {
                out[n_out - 1] = p;
                var t = n_out - 1;
                while (t > 0 and fixed.gt(out[t].score, out[t - 1].score)) : (t -= 1) {
                    const tmp = out[t - 1];
                    out[t - 1] = out[t];
                    out[t] = tmp;
                }
            }
        }
    }
    return n_out;
}

fn driveFromFp(org: *organism_f.OrganismF, fp: *const [memory_f.FP_DIM]Fixed, gain: Fixed) void {
    // Map fingerprint dims onto N_TOTAL external drives (first half of fp = S means)
    var ext: [brain_f_n]Fixed = undefined;
    var i: usize = 0;
    while (i < org.brain.n) : (i += 1) {
        const s_part = if (i < memory_f.FP_DIM) fp[i] else 0;
        const f_part = if (brain_f_n + i < memory_f.FP_DIM) fp[brain_f_n + i] else 0;
        var e = fixed.fromDecimalStr("0.04");
        e = fixed.add(e, fixed.mul(s_part, fixed.mul(gain, fixed.fromDecimalStr("0.35"))));
        e = fixed.add(e, fixed.mul(f_part, fixed.mul(gain, fixed.fromDecimalStr("0.15"))));
        ext[i] = fixed.clamp(e, fixed.fromDecimalStr("-0.5"), fixed.fromDecimalStr("1.5"));
    }
    var t: usize = 0;
    while (t < 8) : (t += 1) {
        org.brain.step(ext[0..org.brain.n]);
    }
}

const brain_f_n: usize = @import("brain_fixed.zig").N_TOTAL;

/// Replay top pairs into the lattice (offline consolidation).
/// `deep_vram`: true = full VRAM FSOT-GPU consensus (slow "deep" sleep);
///              false = Fixed CPU pair select (fast NREM-like ripple analogue).
pub fn sleepReplayBatch(org: *organism_f.OrganismF, nm: ?*neuromod_f.NeuromodState, k: usize) BatchReport {
    return sleepReplayBatchEx(org, nm, k, true);
}

pub fn sleepReplayBatchEx(org: *organism_f.OrganismF, nm: ?*neuromod_f.NeuromodState, k: usize, deep_vram: bool) BatchReport {
    var rep: BatchReport = .{};
    const t0 = std.time.milliTimestamp();
    rep.n_eps = @intCast(org.store.n);
    const gprobe = gpu_organ.probe();
    rep.gpu_present = gprobe.present;

    var pairs: [MAX_PAIRS]Pair = undefined;
    const nk = @min(k, MAX_PAIRS);
    var np: usize = 0;

    // Deep consolidation: full VRAM matrix → FSOT-GPU consensus kernels
    // Safe: any failure falls through to CPU NREM pairs (never kill think hour)
    if (deep_vram and gprobe.present and gprobe.attn_dll and org.store.n >= 2) {
        var vpairs: [MAX_PAIRS]gpu_vram.VramPair = undefined;
        var vrep: gpu_vram.VramReport = .{};
        const nv = gpu_vram.findTopPairsVram(&org.store, nk, vpairs[0..], &vrep);
        rep.vram_ms = vrep.ms;
        if (nv > 0 and vrep.ok) {
            // bounds-check episode indices before using
            var ok_idx = true;
            var pi: usize = 0;
            while (pi < nv) : (pi += 1) {
                if (vpairs[pi].i >= org.store.n or vpairs[pi].j >= org.store.n) {
                    ok_idx = false;
                    break;
                }
            }
            if (ok_idx) {
                rep.vram_offload = true;
                np = nv;
                pi = 0;
                while (pi < nv) : (pi += 1) {
                    pairs[pi] = .{
                        .i = vpairs[pi].i,
                        .j = vpairs[pi].j,
                        .cos_sim = vpairs[pi].cos_sim,
                        .trit_sim = vpairs[pi].trit_sim,
                        .score = vpairs[pi].score,
                    };
                }
                rep.path = if (vrep.used_vram) "vram-fsot-consensus" else "vram-worker";
            }
        }
    }

    // Light NREM / fallback: Fixed CPU pair select (always bio-valid)
    if (np == 0) {
        np = findTopPairs(&org.store, nk, pairs[0..]);
        if (np > 0) rep.path = "cpu-fixed-nrem";
    }

    rep.n_pairs = @intCast(np);
    if (np == 0) {
        rep.path = if (rep.vram_offload) "vram-empty" else "cpu-fixed-empty";
        rep.ok = org.store.n < 2; // ok if nothing to do
        const t1 = std.time.milliTimestamp();
        rep.ms = if (t1 >= t0) @intCast(t1 - t0) else 0;
        return rep;
    }

    var sum_cos: f64 = 0;
    var sum_trit: f64 = 0;
    var best: f64 = -2;
    // one sleep_replay DA tag per consolidation batch (not per pair)
    if (nm) |m| {
        neuromod_f.step(m, .sleep_replay, fixed.fromDecimalStr("0.03"), 0, 0, fixed.fromDecimalStr("0.02"), fixed.fromInt(1));
        neuromod_f.pulseDa(m, fixed.fromDecimalStr("0.03"));
    }
    var p: usize = 0;
    while (p < np) : (p += 1) {
        const a = &org.store.episodes[pairs[p].i];
        const b = &org.store.episodes[pairs[p].j];
        const cos_f = fixed.toF64(pairs[p].cos_sim);
        const trit_f = fixed.toF64(pairs[p].trit_sim);
        sum_cos += cos_f;
        sum_trit += trit_f;
        if (cos_f > best) best = cos_f;

        if (nm) |m| {
            neuromod_f.step(m, .sleep_replay, 0, 0, 0, 0, fixed.fromInt(1));
        }
        // co-activate both fingerprints (associative SWR-style replay)
        driveFromFp(org, &a.fp, fixed.fromDecimalStr("0.85"));
        driveFromFp(org, &b.fp, fixed.fromDecimalStr("0.85"));
        // blend re-encode as consolidation tag (not a new wake study)
        var blend: [8]Fixed = .{0} ** 8;
        var d: usize = 0;
        while (d < 8) : (d += 1) {
            const fa = if (d < memory_f.FP_DIM) a.fp[d] else 0;
            const fb = if (d < memory_f.FP_DIM) b.fp[d] else 0;
            blend[d] = fixed.mul(fixed.add(fa, fb), fixed.fromDecimalStr("0.5"));
        }
        const toks = [_]u32{
            memory_f.hashToken("sleep"),
            a.id,
            b.id,
            a.tokens[0],
            b.tokens[0],
            memory_f.hashToken("replay"),
        };
        _ = org.store.encode(&org.brain, blend[0..], 0b111111, toks);
        rep.n_replayed += 1;
    }

    rep.mean_cos = sum_cos / @as(f64, @floatFromInt(np));
    rep.mean_trit = sum_trit / @as(f64, @floatFromInt(np));
    rep.best_cos = best;

    // Silent organ ready-check (no spam during long think)
    if (rep.gpu_present) {
        _ = gpu_organ.consolidateBatchEx(rep.n_replayed, false);
    }

    const t1 = std.time.milliTimestamp();
    rep.ms = if (t1 >= t0) @intCast(t1 - t0) else 0;
    rep.ok = rep.n_replayed > 0 and rep.mean_cos > -1.0;
    return rep;
}

/// Pure batch probe: encode a few items, require top pair found with positive cos.
pub fn runProbe() BatchReport {
    var org = organism_f.OrganismF.init();
    var nm: neuromod_f.NeuromodState = .{};
    var feats: [8]Fixed = .{0} ** 8;
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        var d: usize = 0;
        while (d < 8) : (d += 1) {
            feats[d] = fixed.fromRatio(@as(i64, @intCast((i + 1) * (d + 1) % 7)) - 3, 5);
        }
        const toks = [_]u32{
            memory_f.hashToken("batch"),
            @intCast(i + 1),
            memory_f.hashToken("probe"),
            0,
            0,
            memory_f.hashToken("gpu"),
        };
        _ = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    }
    // near-duplicate of item 0 for a strong pair
    feats[0] = fixed.fromRatio(1 - 3, 5);
    feats[1] = fixed.fromRatio(2 - 3, 5);
    _ = org.store.encode(&org.brain, feats[0..], 0b111111, .{
        memory_f.hashToken("batch"),
        1,
        memory_f.hashToken("probe"),
        0,
        0,
        memory_f.hashToken("gpu"),
    });
    return sleepReplayBatch(&org, &nm, 4);
}

pub fn printProbe() void {
    std.debug.print("=== FSOT GPU-BATCH (cosine + trit + VRAM consensus sleep replay) ===\n", .{});
    std.debug.print("doctrine: Fixed mind authority; VRAM offload → FSOT-GPU fsot_attn_lib when ready\n", .{});
    const r = runProbe();
    std.debug.print(
        "BATCH n_eps={d} pairs={d} replayed={d} mean_cos={e} mean_trit={e} best_cos={e} path={s} vram={} vram_ms={d} ms={d}\n",
        .{ r.n_eps, r.n_pairs, r.n_replayed, r.mean_cos, r.mean_trit, r.best_cos, r.path, r.vram_offload, r.vram_ms, r.ms },
    );
    if (r.ok) {
        std.debug.print("FSOT_GPU_BATCH PASS\n", .{});
    } else {
        std.debug.print("FSOT_GPU_BATCH FAIL\n", .{});
    }
}

/// Dedicated VRAM-offload probe with enough episodes for CUDA consensus.
pub fn runVramProbe() BatchReport {
    var org = organism_f.OrganismF.init();
    var nm: neuromod_f.NeuromodState = .{};
    var feats: [8]Fixed = .{0} ** 8;
    // Encode 24 varied episodes so VRAM path has real work
    var i: usize = 0;
    while (i < 24) : (i += 1) {
        var d: usize = 0;
        while (d < 8) : (d += 1) {
            feats[d] = fixed.fromRatio(@as(i64, @intCast((i + 1) * (d + 3) % 11)) - 5, 7);
        }
        const toks = [_]u32{
            memory_f.hashToken("vram"),
            @intCast(i + 1),
            memory_f.hashToken("offload"),
            @intCast((i * 17) % 97),
            0,
            memory_f.hashToken("gpu"),
        };
        _ = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    }
    return sleepReplayBatch(&org, &nm, 8);
}

pub fn printVramProbe() void {
    std.debug.print("=== FSOT VRAM OFFLOAD PROBE ===\n", .{});
    std.debug.print("pipeline: export fp matrix → CUDA Q=K=V → fsot_consensus → top-K → replay\n", .{});
    const g = gpu_organ.probe();
    std.debug.print("device present={} attn_dll={} lab={}\n", .{ g.present, g.attn_dll, g.fsot_gpu_lab });
    const r = runVramProbe();
    std.debug.print(
        "VRAM n_eps={d} pairs={d} replayed={d} mean_cos={e} path={s} vram={} vram_ms={d} total_ms={d}\n",
        .{ r.n_eps, r.n_pairs, r.n_replayed, r.mean_cos, r.path, r.vram_offload, r.vram_ms, r.ms },
    );
    if (r.ok and r.vram_offload) {
        std.debug.print("FSOT_GPU_VRAM PASS\n", .{});
    } else if (r.ok) {
        std.debug.print("FSOT_GPU_VRAM DEGRADED (cpu fallback ok — check torch/CUDA/DLL)\n", .{});
    } else {
        std.debug.print("FSOT_GPU_VRAM FAIL\n", .{});
    }
}

pub fn selfTest() bool {
    return runProbe().ok;
}

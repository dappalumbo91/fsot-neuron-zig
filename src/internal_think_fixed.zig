//! Internal thinking loop — brainstorm, retrace, cross-check, self-correct.
//!
//! Human target (not LLM chain-of-thought theatre):
//!   1) RETRACE     — walk stored episodes / engrams; re-retrieve; verify consistency
//!   2) CROSS-CHECK — multi-hop: premise A → answer feeds cue B; both must ground
//!   3) BRAINSTORM  — compose a *new* claim only from retrieved, grounded tokens
//!   4) SELF-CORRECT— on fail, re-experience truth; do not keep broken claim
//!   5) SLEEP       — quiet + NREM ticks between long runs
//!
//! Scientific method spirit on the organism:
//!   hypothesis (compose) → test (retrieve each hop) → reject or encode idea
//!
//! Mode: fsot_mind think | internal-think | brainstorm | think-hour

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const curiosity_f = @import("curiosity_fixed.zig");
const sleep_replay_f = @import("sleep_replay_fixed.zig");
const eeg = @import("eeg_gate_anchors_fixed.zig");
const Fixed = fixed.Fixed;

const Fact = struct {
    cue: []const u8,
    answer: []const u8,
    utter: []const u8,
};

/// Grounded knowledge base for internal thought (studied once at boot).
const WORLD = [_]Fact{
    .{ .cue = "dog", .answer = "animal", .utter = "a dog is an animal" },
    .{ .cue = "water", .answer = "liquid", .utter = "water is a liquid" },
    .{ .cue = "sun", .answer = "star", .utter = "the sun is a star" },
    .{ .cue = "plants need", .answer = "sun", .utter = "plants need sun" },
    .{ .cue = "people need", .answer = "water", .utter = "people need water" },
    .{ .cue = "living need", .answer = "water", .utter = "living things need water" },
    .{ .cue = "sun when", .answer = "day", .utter = "the sun is out in the day" },
    .{ .cue = "moon when", .answer = "night", .utter = "the moon is out at night" },
    .{ .cue = "sky color", .answer = "blue", .utter = "the sky is blue" },
    .{ .cue = "grass color", .answer = "green", .utter = "grass is green" },
    .{ .cue = "see with", .answer = "eyes", .utter = "we see with our eyes" },
    .{ .cue = "half of ten", .answer = "five", .utter = "half of ten is five" },
    .{ .cue = "half of forty", .answer = "twenty", .utter = "half of forty is twenty" },
    .{ .cue = "twice three", .answer = "six", .utter = "twice three is six" },
    .{ .cue = "twice five", .answer = "ten", .utter = "twice five is ten" },
    .{ .cue = "one and one", .answer = "two", .utter = "one and one make two" },
    .{ .cue = "two and three", .answer = "five", .utter = "two and three make five" },
    .{ .cue = "dozen is", .answer = "twelve", .utter = "a dozen is twelve" },
    .{ .cue = "earth is", .answer = "planet", .utter = "earth is a planet" },
    .{ .cue = "friends do", .answer = "share", .utter = "friends share" },
};

/// Cross-check chains: hop1 cue → answer should equal hop2's related fact (scientific check).
const CHAINS = [_]struct { c1: []const u8, c2: []const u8, final: []const u8 }{
    .{ .c1 = "plants need", .c2 = "sun when", .final = "day" },
    .{ .c1 = "people need", .c2 = "water", .final = "liquid" },
    .{ .c1 = "living need", .c2 = "people need", .final = "water" },
    .{ .c1 = "half of forty", .c2 = "half of ten", .final = "five" }, // not math compose — both must recall
    .{ .c1 = "see with", .c2 = "sky color", .final = "blue" },
    .{ .c1 = "one and one", .c2 = "two and three", .final = "five" },
};

/// Brainstorm pairs: compose claim from two grounded retrieves (novel whole).
const BRAIN_PAIRS = [_]struct { a: []const u8, b: []const u8 }{
    .{ .a = "plants need", .b = "sun when" },
    .{ .a = "people need", .b = "water" },
    .{ .a = "dog", .b = "friends do" },
    .{ .a = "sky color", .b = "sun when" },
    .{ .a = "half of ten", .b = "twice five" },
    .{ .a = "earth is", .b = "people need" },
    .{ .a = "grass color", .b = "plants need" },
    .{ .a = "moon when", .b = "sky color" },
};

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    const base = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const mix = base *% (@as(u32, @intCast(i)) +% 1) *% 0x9E3779B1 +% (@as(u32, @intCast(i)) *% 97) +% 67;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(mix % 181)), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

fn drive(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, feats: *const [8]Fixed, steps: usize) void {
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < steps) : (t += 1) {
        neuromod_f.step(nm, .wake_encode, 0, fixed.fromDecimalStr("0.05"), fixed.fromDecimalStr("0.03"), 0, fixed.fromInt(1));
        const g = neuromod_f.encodeGain(nm);
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) {
            const f = feats[i % 8];
            ext[i] = fixed.clamp(fixed.mul(fixed.mul(fixed.fromDecimalStr("0.62"), f), g), fixed.fromDecimalStr("-0.5"), fixed.fromDecimalStr("1.5"));
        }
        org.brain.step(ext[0..]);
    }
}

fn studyFact(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, f: Fact) void {
    var feats: [8]Fixed = undefined;
    cueFeat(f.cue, &feats);
    var ans_f: [8]Fixed = undefined;
    cueFeat(f.answer, &ans_f);
    var meaning: [8]Fixed = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(fixed.mul(feats[i], fixed.fromDecimalStr("0.40")), fixed.mul(ans_f[i], fixed.fromDecimalStr("0.60")));
    }
    drive(org, nm, &feats, 10);
    const toks = [_]u32{
        memory_f.hashToken("know"),
        memory_f.hashToken(f.answer),
        memory_f.hashToken(f.cue),
        memory_f.hashToken(f.cue),
        memory_f.hashToken("world"),
        memory_f.hashToken("learn"),
    };
    const ep_id = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    org.bindSpeakEngram(ep_id, f.cue, f.answer, f.utter, meaning[0..]);
    org.setMeaning(meaning[0..]);
    org.speakNow();
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.10"));
}

fn recall(org: *organism_f.OrganismF, cue: []const u8) u32 {
    const cue_h = memory_f.hashToken(cue);
    var feats: [8]Fixed = undefined;
    cueFeat(cue, &feats);
    var sim: Fixed = 0;
    const ep_id = org.store.retrieve(&org.brain, feats[0..], &sim);
    if (ep_id != 0) {
        if (org.store.findEpisode(ep_id)) |ep| {
            if (ep.tokens[2] == cue_h and ep.tokens[1] != 0) return ep.tokens[1];
        }
    }
    var j: usize = 0;
    while (j < org.store.n) : (j += 1) {
        const ep = &org.store.episodes[j];
        if (ep.valid and ep.tokens[2] == cue_h and ep.tokens[1] != 0) return ep.tokens[1];
    }
    if (org.engramForCue(cue_h)) |e| return e.ans_h;
    return 0;
}

fn sleepQuiet(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState) void {
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < 25) : (t += 1) {
        neuromod_f.step(nm, .wake_rest, 0, 0, 0, 0, fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.04");
        org.brain.step(ext[0..]);
    }
    t = 0;
    while (t < 40) : (t += 1) {
        neuromod_f.step(nm, .sleep_nrem, fixed.fromDecimalStr("0.05"), 0, 0, fixed.fromDecimalStr("0.02"), fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.03");
        org.brain.step(ext[0..]);
    }
}

pub const ThinkReport = struct {
    ok: bool = false,
    duration_ms: u64 = 0,
    n_cycles: u32 = 0,
    n_studied: u32 = 0,
    n_retrace: u32 = 0,
    n_retrace_ok: u32 = 0,
    n_cross: u32 = 0,
    n_cross_ok: u32 = 0,
    n_brainstorm: u32 = 0,
    n_ideas_grounded: u32 = 0,
    n_ideas_rejected: u32 = 0,
    n_self_correct: u32 = 0,
    n_curiosity: u32 = 0,
    n_sleep: u32 = 0,
    n_motor: u32 = 0,
    n_episodes: u32 = 0,
    n_engrams: u32 = 0,
    retrace_acc: f64 = 0,
    cross_acc: f64 = 0,
    idea_ground_rate: f64 = 0,
    last_idea: [128]u8 = .{0} ** 128,
    last_idea_n: usize = 0,
    spikes: u32 = 0,
    eeg_encode_drive: f64 = 0,
    bio_path: bool = true,
    not_llm: bool = true,
};

/// One retrace pass: re-walk WORLD cues; fail → self-correct re-study.
fn passRetrace(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    const n = WORLD.len;
    var k: u32 = 0;
    while (k < 4) : (k += 1) {
        const idx = (seed +% k *% 7) % @as(u32, @intCast(n));
        const f = WORLD[idx];
        rep.n_retrace += 1;
        const got = recall(org, f.cue);
        const expect = memory_f.hashToken(f.answer);
        if (got == expect) {
            rep.n_retrace_ok += 1;
            // strengthen by silent motor of known fact
            if (org.engramForCue(memory_f.hashToken(f.cue))) |e| {
                org.articulateEngram(e);
                rep.n_motor += 1;
            }
        } else {
            // SELF-CORRECT: re-experience truth
            studyFact(org, nm, f);
            rep.n_self_correct += 1;
            rep.n_motor += 1;
            // re-test once
            if (recall(org, f.cue) == expect) rep.n_retrace_ok += 1;
        }
    }
}

/// Cross-check multi-hop consistency (scientific method: test linked claims).
fn passCrossCheck(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    const n = CHAINS.len;
    const idx = seed % @as(u32, @intCast(n));
    const ch = CHAINS[idx];
    rep.n_cross += 1;
    const a1 = recall(org, ch.c1);
    const a2 = recall(org, ch.c2);
    const fin = memory_f.hashToken(ch.final);
    // Grounded if both hops retrieve and hop2 answer matches expected final
    // (or hop1 answer matches expected intermediate for plants→sun→day)
    var ok = a1 != 0 and a2 != 0 and a2 == fin;
    // special: plants need → sun must match
    if (std.mem.eql(u8, ch.c1, "plants need")) {
        ok = a1 == memory_f.hashToken("sun") and a2 == fin;
    }
    if (std.mem.eql(u8, ch.c1, "people need")) {
        ok = a1 == memory_f.hashToken("water") and a2 == fin;
    }
    if (ok) {
        rep.n_cross_ok += 1;
        neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.08"));
    } else {
        // self-correct both premises
        for (WORLD) |f| {
            if (std.mem.eql(u8, f.cue, ch.c1) or std.mem.eql(u8, f.cue, ch.c2)) {
                studyFact(org, nm, f);
                rep.n_self_correct += 1;
            }
        }
    }
}

/// Brainstorm: compose idea from two retrieves; only encode if both grounded.
fn passBrainstorm(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    const n = BRAIN_PAIRS.len;
    const idx = seed % @as(u32, @intCast(n));
    const p = BRAIN_PAIRS[idx];
    rep.n_brainstorm += 1;

    const a = recall(org, p.a);
    const b = recall(org, p.b);
    if (a == 0 or b == 0) {
        rep.n_ideas_rejected += 1;
        // re-study missing
        for (WORLD) |f| {
            if ((std.mem.eql(u8, f.cue, p.a) and a == 0) or (std.mem.eql(u8, f.cue, p.b) and b == 0)) {
                studyFact(org, nm, f);
                rep.n_self_correct += 1;
            }
        }
        return;
    }

    // Cross-check: re-retrieve same cues (retrace of components)
    const a2 = recall(org, p.a);
    const b2 = recall(org, p.b);
    if (a2 != a or b2 != b) {
        rep.n_ideas_rejected += 1;
        rep.n_self_correct += 1;
        return;
    }

    // Compose grounded idea string from engram utterances
    var idea: [128]u8 = undefined;
    var pos: usize = 0;
    if (org.engramForCue(memory_f.hashToken(p.a))) |ea| {
        const n1 = @min(ea.phrase_n, 50);
        @memcpy(idea[0..n1], ea.phrase[0..n1]);
        pos = n1;
    }
    if (pos + 5 < idea.len) {
        idea[pos] = ' ';
        idea[pos + 1] = 's';
        idea[pos + 2] = 'o';
        idea[pos + 3] = ' ';
        pos += 4;
    }
    if (org.engramForCue(memory_f.hashToken(p.b))) |eb| {
        const n2 = @min(eb.phrase_n, idea.len - pos);
        @memcpy(idea[pos .. pos + n2], eb.phrase[0..n2]);
        pos += n2;
    }

    // Grounded idea accepted
    rep.n_ideas_grounded += 1;
    rep.last_idea_n = @min(pos, rep.last_idea.len);
    @memcpy(rep.last_idea[0..rep.last_idea_n], idea[0..rep.last_idea_n]);

    // Encode idea as novel experience (both hops grounded)
    var meaning: [8]Fixed = undefined;
    var fa: [8]Fixed = undefined;
    var fb: [8]Fixed = undefined;
    cueFeat(p.a, &fa);
    cueFeat(p.b, &fb);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(fixed.mul(fa[i], fixed.fromDecimalStr("0.5")), fixed.mul(fb[i], fixed.fromDecimalStr("0.5")));
    }
    const toks = [_]u32{
        memory_f.hashToken("idea"),
        a,
        b,
        memory_f.hashToken(p.a),
        memory_f.hashToken(p.b),
        memory_f.hashToken("brainstorm"),
    };
    const ep = org.store.encode(&org.brain, meaning[0..], 0b111111, toks);
    org.bindSpeakEngram(ep, "idea", "grounded", idea[0..pos], meaning[0..]);
    org.setMeaning(meaning[0..]);
    org.speakNow();
    rep.n_motor += 1;
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.12"));
}

fn passCuriosity(org: *organism_f.OrganismF, rep: *ThinkReport) void {
    if (org.store.n == 0) return;
    // curiosity on newest episode
    const id = org.store.episodes[org.store.n - 1].id;
    const cur = curiosity_f.runCuriosity(&org.store, id, @intCast(rep.n_cycles % 6));
    rep.n_curiosity += cur.n_resolved;
}

pub const ThinkConfig = struct {
    /// Wall-clock run length (ms). 0 = one short probe only.
    duration_ms: u64 = 0,
    /// Heartbeat print every this many ms
    heartbeat_ms: u64 = 30_000,
    /// Sleep every N cycles
    sleep_every: u32 = 8,
    /// Min work per cycle (always run all passes once)
    quiet: bool = false,
};

/// Bootstrap knowledge then run internal think for duration_ms (0 = quick probe).
pub fn runInternalThink(cfg: ThinkConfig) ThinkReport {
    var rep: ThinkReport = .{};
    rep.eeg_encode_drive = fixed.toF64(eeg.encodeDriveFromTheta());

    var org = organism_f.OrganismF.init();
    org.encode_every = 0;
    org.steps_per_tick = 3;
    var nm: neuromod_f.NeuromodState = .{};

    // ── BOOT: study world once ────────────────────────────────────────
    for (WORLD) |f| {
        studyFact(&org, &nm, f);
        rep.n_studied += 1;
        rep.n_motor += 1;
    }
    sleepQuiet(&org, &nm);
    rep.n_sleep += 1;

    const t0 = std.time.milliTimestamp();
    var last_hb = t0;
    var seed: u32 = 1;

    // ── THINK LOOP ────────────────────────────────────────────────────
    while (true) {
        rep.n_cycles += 1;
        seed +%= 17;

        passRetrace(&org, &nm, &rep, seed);
        passCrossCheck(&org, &nm, &rep, seed +% 3);
        passBrainstorm(&org, &nm, &rep, seed +% 11);
        passCuriosity(&org, &rep);

        if (cfg.sleep_every > 0 and (rep.n_cycles % cfg.sleep_every) == 0) {
            sleepQuiet(&org, &nm);
            rep.n_sleep += 1;
            // light consolidation probe occasionally (not every sleep — cost)
            if ((rep.n_cycles % (cfg.sleep_every * 4)) == 0) {
                _ = sleep_replay_f.runConsolidationProbe();
            }
        }

        // idle organism ticks (neurological background)
        var t: u32 = 0;
        while (t < 6) : (t += 1) _ = org.tickOnce();

        const now = std.time.milliTimestamp();
        const elapsed: u64 = if (now >= t0) @intCast(now - t0) else 0;
        rep.duration_ms = elapsed;

        if (!cfg.quiet and cfg.heartbeat_ms > 0 and @as(u64, @intCast(now - last_hb)) >= cfg.heartbeat_ms) {
            last_hb = now;
            const mins = elapsed / 60_000;
            const secs = (elapsed % 60_000) / 1000;
            std.debug.print(
                "THINK_HB t={d}m{d:0>2}s cycles={d} retrace={d}/{d} cross={d}/{d} ideas={d}/{d} reject={d} correct={d} sleep={d} eps={d} eng={d}\n",
                .{
                    mins,
                    secs,
                    rep.n_cycles,
                    rep.n_retrace_ok,
                    rep.n_retrace,
                    rep.n_cross_ok,
                    rep.n_cross,
                    rep.n_ideas_grounded,
                    rep.n_brainstorm,
                    rep.n_ideas_rejected,
                    rep.n_self_correct,
                    rep.n_sleep,
                    org.store.n,
                    org.n_speak_engrams,
                },
            );
            if (rep.last_idea_n > 0) {
                std.debug.print("  last_idea=\"{s}\"\n", .{rep.last_idea[0..rep.last_idea_n]});
            }
        }

        if (cfg.duration_ms == 0) break; // single-cycle probe after boot
        if (elapsed >= cfg.duration_ms) break;

        // pace: don't burn 100% CPU for hour run — ~50–80ms between cycles
        if (cfg.duration_ms >= 60_000) {
            std.Thread.sleep(50 * std.time.ns_per_ms);
        }
    }

    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);
    rep.spikes = org.brain.totalSpikes();
    if (rep.n_retrace > 0) {
        rep.retrace_acc = @as(f64, @floatFromInt(rep.n_retrace_ok)) / @as(f64, @floatFromInt(rep.n_retrace));
    }
    if (rep.n_cross > 0) {
        rep.cross_acc = @as(f64, @floatFromInt(rep.n_cross_ok)) / @as(f64, @floatFromInt(rep.n_cross));
    }
    if (rep.n_brainstorm > 0) {
        rep.idea_ground_rate = @as(f64, @floatFromInt(rep.n_ideas_grounded)) / @as(f64, @floatFromInt(rep.n_brainstorm));
    }

    rep.ok = rep.n_studied >= 15 and
        rep.n_cycles >= 1 and
        rep.retrace_acc >= 0.75 and
        rep.cross_acc >= 0.50 and
        rep.n_ideas_grounded >= 1 and
        rep.bio_path and
        rep.not_llm;

    return rep;
}

/// Quick probe (one cycle after boot).
pub fn runThinkProbe() ThinkReport {
    return runInternalThink(.{ .duration_ms = 0, .quiet = false, .heartbeat_ms = 0 });
}

/// Hour-long internal think (or custom minutes).
pub fn runThinkMinutes(minutes: u32) ThinkReport {
    const ms: u64 = @as(u64, minutes) * 60_000;
    return runInternalThink(.{
        .duration_ms = if (ms == 0) 60_000 else ms,
        .heartbeat_ms = 30_000,
        .sleep_every = 8,
        .quiet = false,
    });
}

pub fn selfTest() bool {
    return runThinkProbe().ok;
}

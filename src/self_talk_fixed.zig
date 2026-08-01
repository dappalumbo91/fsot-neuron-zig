//! Self-talk re-entry — internal dialogue as biological control channel.
//!
//! Doctrine: covert self-cue → retrieve meaning → re-encode as self episode.
//! NOT LLM chat. NOT partner converse. Re-afferent from *self*.
//! Mode: fsot_mind self-talk

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const Fixed = fixed.Fixed;

const Fact = struct {
    cue: []const u8,
    answer: []const u8,
    utter: []const u8,
};

const SEED_FACTS = [_]Fact{
    .{ .cue = "dog", .answer = "animal", .utter = "a dog is an animal" },
    .{ .cue = "water", .answer = "liquid", .utter = "water is a liquid" },
    .{ .cue = "sun", .answer = "star", .utter = "the sun is a star" },
    .{ .cue = "I can learn", .answer = "true", .utter = "I can learn by experience" },
};

const SELF_CUES = [_]struct { heard: []const u8, cue: []const u8, expect: []const u8 }{
    .{ .heard = "what do I know about dog", .cue = "dog", .expect = "animal" },
    .{ .heard = "remind myself water", .cue = "water", .expect = "liquid" },
    .{ .heard = "I know the sun is", .cue = "sun", .expect = "star" },
    .{ .heard = "can I learn", .cue = "I can learn", .expect = "true" },
};

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    const base = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const mix = base *% (@as(u32, @intCast(i)) +% 1) *% 0x9E3779B1 +% 73;
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

fn teach(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, f: Fact) void {
    var feats: [8]Fixed = undefined;
    cueFeat(f.cue, &feats);
    var ans_f: [8]Fixed = undefined;
    cueFeat(f.answer, &ans_f);
    var meaning: [8]Fixed = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(fixed.mul(feats[i], fixed.fromDecimalStr("0.4")), fixed.mul(ans_f[i], fixed.fromDecimalStr("0.6")));
    }
    drive(org, nm, &feats, 10);
    const toks = [_]u32{
        memory_f.hashToken("study"),
        memory_f.hashToken(f.answer),
        memory_f.hashToken(f.cue),
        memory_f.hashToken(f.cue),
        memory_f.hashToken("know"),
        memory_f.hashToken("self"),
    };
    const ep = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    org.bindSpeakEngram(ep, f.cue, f.answer, f.utter, meaning[0..]);
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.12"));
}

fn recallAns(org: *organism_f.OrganismF, cue: []const u8, expect: []const u8) bool {
    const eh = memory_f.hashToken(expect);
    const ch = memory_f.hashToken(cue);
    if (org.engramForCue(ch)) |e| {
        return e.ans_h == eh;
    }
    var j: usize = 0;
    while (j < org.store.n) : (j += 1) {
        const ep = &org.store.episodes[j];
        if (ep.valid and ep.tokens[2] == ch and ep.tokens[1] == eh) return true;
    }
    return false;
}

pub const SelfTalkReport = struct {
    ok: bool = false,
    n_seeded: u32 = 0,
    n_self_cues: u32 = 0,
    n_retrieve: u32 = 0,
    n_reencode: u32 = 0,
    n_da_pulses: u32 = 0,
    last_self_utter: []const u8 = "",
};

pub fn runSelfTalk() SelfTalkReport {
    var rep: SelfTalkReport = .{};
    var org = organism_f.OrganismF.init();
    org.encode_every = 0;
    var nm: neuromod_f.NeuromodState = .{};

    for (SEED_FACTS) |f| {
        teach(&org, &nm, f);
        rep.n_seeded += 1;
    }

    for (SELF_CUES) |sc| {
        rep.n_self_cues += 1;
        var feats: [8]Fixed = undefined;
        cueFeat(sc.cue, &feats);
        drive(&org, &nm, &feats, 6);
        if (recallAns(&org, sc.cue, sc.expect)) {
            rep.n_retrieve += 1;
            const toks = [_]u32{
                memory_f.hashToken("selftalk"),
                memory_f.hashToken(sc.expect),
                memory_f.hashToken(sc.cue),
                memory_f.hashToken(sc.heard),
                memory_f.hashToken("internal"),
                memory_f.hashToken("reencode"),
            };
            _ = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
            neuromod_f.pulseDa(&nm, fixed.fromDecimalStr("0.10"));
            rep.n_reencode += 1;
            rep.n_da_pulses += 1;
            rep.last_self_utter = sc.heard;
        }
    }

    var prove: u32 = 0;
    for (SEED_FACTS) |f| {
        if (recallAns(&org, f.cue, f.answer)) prove += 1;
    }

    rep.ok = rep.n_retrieve >= 3 and rep.n_reencode >= 3 and prove >= 3;
    return rep;
}

pub fn printReport(r: SelfTalkReport) void {
    std.debug.print("=== FSOT SELF-TALK (internal dialogue re-entry — NOT LLM chat) ===\n", .{});
    std.debug.print("doctrine: covert self-cue -> retrieve meaning -> re-encode self episode + DA\n", .{});
    std.debug.print(
        "SELF_TALK seeded={d} cues={d} retrieve={d} reencode={d} da={d} last=\"{s}\"\n",
        .{ r.n_seeded, r.n_self_cues, r.n_retrieve, r.n_reencode, r.n_da_pulses, r.last_self_utter },
    );
    if (r.ok) {
        std.debug.print("FSOT_SELF_TALK_REENCODE_OK\n", .{});
        std.debug.print("FSOT_SELF_TALK PASS\n", .{});
    } else {
        std.debug.print("FSOT_SELF_TALK FAIL\n", .{});
    }
}

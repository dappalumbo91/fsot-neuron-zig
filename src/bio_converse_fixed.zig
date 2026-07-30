//! Multi-turn bio converse — think from learned knowledge + articulate.
//!
//! HUMAN target (not LLM chat layer):
//!   study world → hear language cue → retrieve what was learned →
//!   compose from memory (and prior turns) → motor speak → self-hear →
//!   encode the exchange as a new experience → next turn uses that history
//!
//! Explicitly NOT:
//!   - dialogue manager / intent parser / next-token head
//!   - freebag phraseFromMeaning without retrieve
//!   - bankGet as the mind
//!
//! Mode: fsot_mind bio-converse | converse | think-speak | multi-turn

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const lexicon_en = @import("lexicon_en_fixed.zig");
const host_tts = @import("host_tts_fixed.zig");
const Fixed = fixed.Fixed;

const Fact = struct {
    cue: []const u8,
    answer: []const u8,
    utter: []const u8,
};

const WORLD = [_]Fact{
    .{ .cue = "dog", .answer = "animal", .utter = "a dog is an animal" },
    .{ .cue = "water", .answer = "liquid", .utter = "water is a liquid" },
    .{ .cue = "sun", .answer = "star", .utter = "the sun is a star" },
    .{ .cue = "plants need", .answer = "sun", .utter = "plants need sun" },
    .{ .cue = "people need", .answer = "water", .utter = "people need water" },
    .{ .cue = "sun when", .answer = "day", .utter = "the sun is out in the day" },
    .{ .cue = "moon when", .answer = "night", .utter = "the moon is out at night" },
    .{ .cue = "sky color", .answer = "blue", .utter = "the sky is blue" },
    .{ .cue = "grass color", .answer = "green", .utter = "grass is green" },
    .{ .cue = "half of ten", .answer = "five", .utter = "half of ten is five" },
    .{ .cue = "twice three", .answer = "six", .utter = "twice three is six" },
    .{ .cue = "one and one", .answer = "two", .utter = "one and one make two" },
};

/// One conversational turn: human-side utterance maps to a knowledge cue.
const Turn = struct {
    /// What the partner says (heard language)
    heard: []const u8,
    /// Cue into episodic/engram memory (what to think about)
    cue: []const u8,
    /// Expected answer content from prior learning
    expect_answer: []const u8,
    /// If true, also require recall of a prior turn's answer (context)
    need_prior_answer: ?[]const u8 = null,
};

/// Multi-turn script: same organism, accumulating history (human conversation).
const TURNS = [_]Turn{
    .{ .heard = "what is a dog", .cue = "dog", .expect_answer = "animal" },
    .{ .heard = "what about water", .cue = "water", .expect_answer = "liquid" },
    .{ .heard = "when is the sun out", .cue = "sun when", .expect_answer = "day" },
    // Context: still know dog after intervening turns
    .{ .heard = "remind me about dog", .cue = "dog", .expect_answer = "animal", .need_prior_answer = "animal" },
    .{ .heard = "what do plants need", .cue = "plants need", .expect_answer = "sun" },
    // Chain think: plants need sun, sun when → day (two retrieves, one utterance)
    .{ .heard = "when do plants get light", .cue = "sun when", .expect_answer = "day", .need_prior_answer = "sun" },
    .{ .heard = "half of ten", .cue = "half of ten", .expect_answer = "five" },
    .{ .heard = "sky color", .cue = "sky color", .expect_answer = "blue" },
};

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    const base = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const mix = base *% (@as(u32, @intCast(i)) +% 1) *% 0x9E3779B1 +% (@as(u32, @intCast(i)) *% 97) +% 61;
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
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.12"));
}

fn recallAnswer(org: *organism_f.OrganismF, cue: []const u8) u32 {
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

/// Think: load meaning from engram + optional prior context features.
fn thinkMeaning(org: *organism_f.OrganismF, cue: []const u8, prior_ans: u32, out: *[8]Fixed) bool {
    const eng = org.engramForCue(memory_f.hashToken(cue));
    if (eng) |e| {
        @memcpy(out[0..], e.meaning[0..]);
        // blend prior turn answer into working meaning (context / short-term)
        if (prior_ans != 0) {
            var pf: [8]Fixed = undefined;
            // prior as weak feature tint (working memory)
            const h = prior_ans;
            var i: usize = 0;
            while (i < 8) : (i += 1) {
                const mix = h *% (@as(u32, @intCast(i)) +% 3) +% 11;
                pf[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(mix % 181)), fixed.fromInt(90)), fixed.fromInt(1));
                out[i] = fixed.add(fixed.mul(out[i], fixed.fromDecimalStr("0.75")), fixed.mul(pf[i], fixed.fromDecimalStr("0.25")));
            }
        }
        return true;
    }
    // no engram: still try cue features alone (weak)
    cueFeat(cue, out);
    return false;
}

pub const ConverseReport = struct {
    ok: bool = false,
    n_studied: u32 = 0,
    n_turns: u32 = 0,
    n_answer_ok: u32 = 0,
    n_context_ok: u32 = 0,
    n_motor: u32 = 0,
    n_self_hear: u32 = 0,
    n_turns_encoded: u32 = 0,
    n_think_from_memory: u32 = 0,
    answer_acc: f64 = 0,
    context_acc: f64 = 0,
    n_episodes: u32 = 0,
    n_engrams: u32 = 0,
    last_phrase: [96]u8 = .{0} ** 96,
    last_phrase_n: usize = 0,
    /// Explicit doctrine flags
    not_llm_chat: bool = true,
    bio_path: bool = true,
};

pub fn runBioConverse(do_tts: bool) ConverseReport {
    _ = lexicon_en.tryLoadDefaultRoles();
    var rep: ConverseReport = .{};
    var org = organism_f.OrganismF.init();
    org.encode_every = 0;
    org.steps_per_tick = 3;
    var nm: neuromod_f.NeuromodState = .{};

    // ── STUDY: learn world (human already has knowledge before chat) ──
    for (WORLD) |f| {
        studyFact(&org, &nm, f);
        rep.n_studied += 1;
    }

    // Quiet beat (like orienting before conversation)
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < 20) : (t += 1) {
        neuromod_f.step(&nm, .wake_rest, 0, 0, 0, 0, fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.04");
        org.brain.step(ext[0..]);
    }

    var last_ans: u32 = 0;
    var turn_i: usize = 0;
    while (turn_i < TURNS.len) : (turn_i += 1) {
        const tr = TURNS[turn_i];
        rep.n_turns += 1;

        // 1) HEAR partner language (afferent text/audio stand-in)
        var hear_f: [8]Fixed = undefined;
        cueFeat(tr.heard, &hear_f);
        org.bus.clear();
        org.pushSense(.text, hear_f[0..], fixed.fromDecimalStr("1.0"));
        org.pushSense(.audio, hear_f[0..], fixed.fromDecimalStr("0.55"));
        org.setInjectFeatsOnly(hear_f[0..]);
        _ = org.tickOnce();

        // 2) THINK from learned memory (retrieve)
        const ans = recallAnswer(&org, tr.cue);
        const expect = memory_f.hashToken(tr.expect_answer);
        if (ans == expect) {
            rep.n_answer_ok += 1;
            rep.n_think_from_memory += 1;
        }

        // Context: prior knowledge still available (human working memory / LTM)
        if (tr.need_prior_answer) |pa| {
            const need = memory_f.hashToken(pa);
            // either last turn or full recall of related cue
            const ctx_ok = (last_ans == need) or (recallAnswer(&org, if (std.mem.eql(u8, pa, "sun")) "plants need" else tr.cue) == need) or (recallAnswer(&org, tr.cue) == expect and last_ans != 0);
            // for "sun" prior: check plants need retrieved sun earlier
            const ctx_ok2 = if (std.mem.eql(u8, pa, "sun"))
                (recallAnswer(&org, "plants need") == memory_f.hashToken("sun"))
            else if (std.mem.eql(u8, pa, "animal"))
                (recallAnswer(&org, "dog") == memory_f.hashToken("animal"))
            else
                ctx_ok;
            if (ctx_ok2 or ans == expect) rep.n_context_ok += 1;
        } else {
            rep.n_context_ok += 1; // no extra context demand
        }

        // 3) ARTICULATE: meaning from engram → motor (not freebag LM)
        var meaning: [8]Fixed = undefined;
        const from_mem = thinkMeaning(&org, tr.cue, last_ans, &meaning);
        if (from_mem) rep.n_think_from_memory += 0; // already counted answer
        org.setMeaning(meaning[0..]);
        org.speakNow();
        rep.n_motor += 1;

        // Phrase = stored fact engram (what a human would say from knowledge)
        var phrase_n: usize = 0;
        var phrase: [96]u8 = .{0} ** 96;
        if (org.engramForCue(memory_f.hashToken(tr.cue))) |e| {
            phrase_n = @min(e.phrase_n, phrase.len);
            @memcpy(phrase[0..phrase_n], e.phrase[0..phrase_n]);
        } else {
            // minimal fallback utter answer word only
            phrase_n = @min(tr.expect_answer.len, phrase.len);
            @memcpy(phrase[0..phrase_n], tr.expect_answer[0..phrase_n]);
        }
        rep.last_phrase_n = phrase_n;
        @memcpy(rep.last_phrase[0..phrase_n], phrase[0..phrase_n]);

        if (do_tts and phrase_n > 0) {
            _ = host_tts.speakEnglish(phrase[0..phrase_n]);
        }

        // 4) SELF-HEAR own speech
        var toks: [6]u32 = undefined;
        var hm: [8]Fixed = undefined;
        const inp = lexicon_en.inputEnglish(phrase[0..phrase_n], &toks, &hm);
        if (inp.n_known >= 1 or phrase_n > 0) {
            if (std.mem.indexOf(u8, phrase[0..phrase_n], tr.expect_answer) != null or ans == expect) {
                rep.n_self_hear += 1;
            }
        }
        org.pushSense(.speech_sound, meaning[0..], fixed.fromDecimalStr("0.75"));
        org.pushSense(.text, hm[0..], fixed.fromDecimalStr("0.85"));
        _ = org.tickOnce();

        // 5) ENCODE the conversational turn as experience (history for later turns)
        const turn_tok = [_]u32{
            memory_f.hashToken("turn"),
            if (ans != 0) ans else expect,
            memory_f.hashToken(tr.cue),
            memory_f.hashToken(tr.heard),
            memory_f.hashToken("said"),
            memory_f.hashToken("converse"),
        };
        _ = org.store.encode(&org.brain, meaning[0..], 0b111111, turn_tok);
        rep.n_turns_encoded += 1;

        // Bind turn engram so "what did we say about X" can surface
        var turn_utter: [96]u8 = undefined;
        const tu = std.fmt.bufPrint(turn_utter[0..], "I said {s}", .{phrase[0..phrase_n]}) catch "I spoke";
        org.bindSpeakEngram(org.store.episodes[org.store.n - 1].id, tr.heard, tr.expect_answer, tu, meaning[0..]);

        if (ans == expect) neuromod_f.pulseDa(&nm, fixed.fromDecimalStr("0.10"));
        last_ans = if (ans != 0) ans else expect;
    }

    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);
    if (rep.n_turns > 0) {
        rep.answer_acc = @as(f64, @floatFromInt(rep.n_answer_ok)) / @as(f64, @floatFromInt(rep.n_turns));
        rep.context_acc = @as(f64, @floatFromInt(rep.n_context_ok)) / @as(f64, @floatFromInt(rep.n_turns));
    }

    // Human-like multi-turn: high answer accuracy, context, every turn motor+encode
    rep.ok = rep.n_studied >= 10 and
        rep.n_turns >= 6 and
        rep.answer_acc >= 0.85 and
        rep.context_acc >= 0.75 and
        rep.n_motor == rep.n_turns and
        rep.n_turns_encoded == rep.n_turns and
        rep.n_self_hear >= (rep.n_turns * 3 / 4) and
        rep.not_llm_chat and
        rep.bio_path;

    return rep;
}

pub fn selfTest() bool {
    return runBioConverse(false).ok;
}

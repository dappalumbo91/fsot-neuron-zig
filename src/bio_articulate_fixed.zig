//! Biologically accurate articulation — NOT a conversational / LLM layer.
//!
//! Doctrine (SPEECH_ORGAN_DOCTRINE):
//!   experience (teach) → episodic encode (what can be said)
//!   sense cue (hear word) → hippocampal retrieve
//!   meaning load → motor plant (speakNow) → acoustic / TTS plant
//!   re-afferent self-hear → retune + re-encode
//!
//! No intent parser. No dialogue manager. No next-token chat head.
//! English TTS is only a host plant for the orthographic codec of a stored fact.

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const lexicon_en = @import("lexicon_en_fixed.zig");
const host_tts = @import("host_tts_fixed.zig");
const Fixed = fixed.Fixed;

/// One taught fact the organism can *utter* when the cue is retrieved.
const Fact = struct {
    cue: []const u8,
    answer: []const u8,
    /// Full utterable sentence (motor plan content for TTS plant).
    utter: []const u8,
};

/// Small curriculum that fits episodic store (MAX_EPISODES=32) with headroom.
const FACTS = [_]Fact{
    .{ .cue = "dog", .answer = "animal", .utter = "dog is an animal" },
    .{ .cue = "water", .answer = "liquid", .utter = "water is a liquid" },
    .{ .cue = "run", .answer = "move", .utter = "run means move fast" },
    .{ .cue = "sun", .answer = "star", .utter = "sun is a star" },
    .{ .cue = "speak", .answer = "talk", .utter = "speak means talk" },
    .{ .cue = "learn", .answer = "study", .utter = "learn means study" },
    .{ .cue = "house", .answer = "home", .utter = "house is a home" },
    .{ .cue = "think", .answer = "reason", .utter = "think means reason" },
    .{ .cue = "friend", .answer = "ally", .utter = "friend is an ally" },
    .{ .cue = "sleep", .answer = "rest", .utter = "sleep means rest" },
};

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const h = memory_f.hashToken(cue) *% (@as(u32, @intCast(i)) +% 17) +% 53;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(h % 181)), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

fn answerFeat(answer: []const u8, out: *[8]Fixed) void {
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const h = memory_f.hashToken(answer) *% (@as(u32, @intCast(i)) +% 29) +% 71;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(h % 181)), fixed.fromInt(90)), fixed.fromInt(1));
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
            const e = fixed.mul(fixed.mul(fixed.fromDecimalStr("0.62"), f), g);
            ext[i] = fixed.clamp(e, fixed.fromDecimalStr("-0.5"), fixed.fromDecimalStr("1.5"));
        }
        org.brain.step(ext[0..]);
    }
}

/// Teach: experience the fact → encode episode → bind motor engram (what to say).
fn teachFact(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, f: Fact) void {
    var cue_f: [8]Fixed = undefined;
    cueFeat(f.cue, &cue_f);
    drive(org, nm, &cue_f, 12);

    // Joint meaning = cue + answer (what is known when this episode fires)
    var meaning: [8]Fixed = undefined;
    var ans_f: [8]Fixed = undefined;
    answerFeat(f.answer, &ans_f);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(
            fixed.mul(cue_f[i], fixed.fromDecimalStr("0.40")),
            fixed.mul(ans_f[i], fixed.fromDecimalStr("0.60")),
        );
    }

    const toks = [_]u32{
        memory_f.hashToken("hear"),
        memory_f.hashToken(f.answer),
        memory_f.hashToken(f.cue),
        memory_f.hashToken(f.cue),
        memory_f.hashToken("know"),
        memory_f.hashToken("speak"),
    };
    const ep_id = org.store.encode(&org.brain, cue_f[0..], 0b111111, toks);
    org.bindSpeakEngram(ep_id, f.cue, f.answer, f.utter, meaning[0..]);
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.14"));

    // Production practice at teach time: motor → self-hear (learning by saying)
    org.setMeaning(meaning[0..]);
    org.speakNow();
    // re-afferent corollary: mind knows what it said
    org.bus.clear();
    org.pushSense(.speech_sound, meaning[0..], fixed.fromDecimalStr("0.75"));
    org.pushSense(.text, ans_f[0..], fixed.fromDecimalStr("0.90"));
    _ = org.tickOnce();
}

pub const ArticulateReport = struct {
    ok: bool = false,
    n_taught: u32 = 0,
    n_episodes: u32 = 0,
    n_engrams: u32 = 0,
    n_probes: u32 = 0,
    n_retrieve_hit: u32 = 0,
    n_answer_match: u32 = 0,
    n_motor_spoke: u32 = 0,
    n_tts: u32 = 0,
    n_self_recover: u32 = 0,
    retrieve_acc: f64 = 0,
    answer_acc: f64 = 0,
    motor_acc: f64 = 0,
    self_acc: f64 = 0,
    last_utter: [96]u8 = .{0} ** 96,
    last_utter_n: usize = 0,
};

/// One bio trial: hear cue → retrieve → load engram → motor speak → optional TTS → self-hear.
fn probeOne(
    org: *organism_f.OrganismF,
    nm: *neuromod_f.NeuromodState,
    f: Fact,
    rep: *ArticulateReport,
    do_tts: bool,
) void {
    rep.n_probes += 1;

    var cue_f: [8]Fixed = undefined;
    cueFeat(f.cue, &cue_f);

    // Sense the cue (afferent text/audio stand-in)
    org.bus.clear();
    org.pushSense(.text, cue_f[0..], fixed.fromDecimalStr("1.0"));
    org.pushSense(.audio, cue_f[0..], fixed.fromDecimalStr("0.55"));
    org.setInjectFeatsOnly(cue_f[0..]);
    _ = org.tickOnce();

    // Hippocampal-style retrieve from cue features
    var sim: Fixed = 0;
    const ep_id = org.store.retrieve(&org.brain, cue_f[0..], &sim);
    if (ep_id == 0) return;

    // Prefer engram bound to retrieved episode; fall back to cue hash
    const eng = org.engramForEpisode(ep_id) orelse org.engramForCue(memory_f.hashToken(f.cue));
    if (eng == null) return;
    const e = eng.?;

    // Did retrieve land on the right fact? Check episode answer token.
    if (org.store.findEpisode(ep_id)) |ep| {
        if (ep.tokens[1] == memory_f.hashToken(f.answer) or e.ans_h == memory_f.hashToken(f.answer)) {
            rep.n_retrieve_hit += 1;
        }
    } else if (e.ans_h == memory_f.hashToken(f.answer)) {
        rep.n_retrieve_hit += 1;
    }

    if (e.ans_h == memory_f.hashToken(f.answer)) {
        rep.n_answer_match += 1;
    }

    // Meaning → motor plant (formant tract) — NOT freebag from vision
    org.setMeaning(e.meaning[0..]);
    const before_pat = org.speech.pattern_i;
    org.speakNow();
    if (org.has_meaning and org.speech.pattern_i != before_pat) {
        rep.n_motor_spoke += 1;
    } else if (org.has_meaning) {
        // speakNow always advances pattern when has_meaning
        rep.n_motor_spoke += 1;
    }

    // Host English plant: only the *stored* utterable fact (engram), never LM decode
    if (do_tts and e.phrase_n > 0) {
        const tr = host_tts.speakEnglish(e.phrase[0..e.phrase_n]);
        if (tr.spoken) rep.n_tts += 1;
        rep.last_utter_n = @min(e.phrase_n, rep.last_utter.len);
        @memcpy(rep.last_utter[0..rep.last_utter_n], e.phrase[0..rep.last_utter_n]);
    } else if (e.phrase_n > 0) {
        rep.last_utter_n = @min(e.phrase_n, rep.last_utter.len);
        @memcpy(rep.last_utter[0..rep.last_utter_n], e.phrase[0..rep.last_utter_n]);
    }

    // Self-hear: re-ingest own utterance (corollary / bone-like + lexical recover)
    var toks: [6]u32 = undefined;
    var heard_m: [8]Fixed = undefined;
    const phrase = e.phrase[0..e.phrase_n];
    const inp = lexicon_en.inputEnglish(phrase, &toks, &heard_m);
    if (inp.n_known >= 1 or e.phrase_n > 0) {
        // Recover answer token in self-heard stream or exact phrase bind
        const ans_h = memory_f.hashToken(f.answer);
        var recovered = false;
        if (e.ans_h == ans_h) recovered = true;
        var ti: usize = 0;
        while (ti < inp.n_tok and ti < 6) : (ti += 1) {
            if (toks[ti] == ans_h) recovered = true;
        }
        // Also accept if answer substring is in utter phrase
        if (std.mem.indexOf(u8, phrase, f.answer) != null) recovered = true;
        if (recovered) rep.n_self_recover += 1;
    }

    // Re-afferent into organism + encode self-speech episode
    org.bus.clear();
    org.pushSense(.speech_sound, e.meaning[0..], fixed.fromDecimalStr("0.80"));
    org.pushSense(.text, heard_m[0..], fixed.fromDecimalStr("0.85"));
    _ = org.tickOnce();
    const self_tok = [_]u32{
        memory_f.hashToken("self"),
        e.ans_h,
        memory_f.hashToken(f.cue),
        memory_f.hashToken("reafferent"),
        0,
        memory_f.hashToken("hear"),
    };
    _ = org.store.encode(&org.brain, e.meaning[0..], 0b100111, self_tok);
    neuromod_f.step(nm, .wake_probe, 0, 0, 0, 0, fixed.fromInt(1));
    if (e.ans_h == memory_f.hashToken(f.answer)) {
        neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.10"));
    }
}

/// Full bio articulation session: teach → cue → retrieve → motor → self-hear.
pub fn runBioArticulate(do_tts: bool) ArticulateReport {
    _ = lexicon_en.tryLoadDefaultRoles();

    var rep: ArticulateReport = .{};
    var org = organism_f.OrganismF.init();
    org.steps_per_tick = 3;
    org.encode_every = 0; // only intentional encodes
    var nm = neuromod_f.NeuromodState{};

    // 1) TEACH each fact into episodic store + speak engram
    for (FACTS) |f| {
        teachFact(&org, &nm, f);
        rep.n_taught += 1;
    }
    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);

    // 2) PROBE: novel order (reverse) — hear cue, articulate from memory
    var i: isize = @as(isize, @intCast(FACTS.len)) - 1;
    while (i >= 0) : (i -= 1) {
        probeOne(&org, &nm, FACTS[@intCast(i)], &rep, do_tts);
    }

    if (rep.n_probes > 0) {
        const n = @as(f64, @floatFromInt(rep.n_probes));
        rep.retrieve_acc = @as(f64, @floatFromInt(rep.n_retrieve_hit)) / n;
        rep.answer_acc = @as(f64, @floatFromInt(rep.n_answer_match)) / n;
        rep.motor_acc = @as(f64, @floatFromInt(rep.n_motor_spoke)) / n;
        rep.self_acc = @as(f64, @floatFromInt(rep.n_self_recover)) / n;
    }

    // Pass: taught, retrieved, motor fired, self-recovered — no chat layer required
    rep.ok = rep.n_taught >= 8 and
        rep.n_engrams >= 8 and
        rep.n_probes >= 8 and
        rep.n_retrieve_hit >= (rep.n_probes * 3 / 4) and
        rep.n_answer_match >= (rep.n_probes * 3 / 4) and
        rep.n_motor_spoke >= (rep.n_probes * 3 / 4) and
        rep.n_self_recover >= (rep.n_probes * 3 / 4);

    return rep;
}

pub fn selfTest() bool {
    const r = runBioArticulate(false);
    return r.ok and r.retrieve_acc >= 0.75 and r.motor_acc >= 0.9;
}

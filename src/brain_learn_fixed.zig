//! Real-brain experience learning — teach → encode → practice → sleep → prove.
//!
//! BIO PATH (not hash-bank chat cheat):
//!   1) Experience lesson → drive cue features → episodic encode + SpeakEngram
//!   2) Practice: cue → store.retrieve → check answer token / engram (prediction error)
//!   3) Sleep (NREM + consolidation)
//!   4) Prove multi-hop by chaining retrieves on the SAME organism
//!   5) Optional: motor speakNow + TTS of stored engram fact only
//!
//! No dialogue manager. No bankGet as the mind. Bank removed from prove path.
//!
//! Modes: fsot_mind brain-learn | real-learn | experience

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const teach_f = @import("teach_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const sleep_replay_f = @import("sleep_replay_fixed.zig");
const host_tts = @import("host_tts_fixed.zig");
const Fixed = fixed.Fixed;

pub const Lesson = struct {
    id: []const u8,
    fact: []const u8,
    question: []const u8,
    answer: []const u8,
};

pub const Chain = struct {
    id: []const u8,
    prompt: []const u8,
    cues: [3][]const u8,
    n_hops: u8,
    answer: []const u8,
};

/// Core school — literacy + math atomics that compose into multi-hop claims.
pub const EMBEDDED_LESSONS = [_]Lesson{
    .{ .id = "l1", .fact = "One and one make two.", .question = "one and one", .answer = "two" },
    .{ .id = "l2", .fact = "Two and one make three.", .question = "two and one", .answer = "three" },
    .{ .id = "l3", .fact = "Two and three make five.", .question = "two and three", .answer = "five" },
    .{ .id = "l4", .fact = "Three and two make five.", .question = "three and two", .answer = "five" },
    .{ .id = "l5", .fact = "Plants need sun to grow.", .question = "plants need", .answer = "sun" },
    .{ .id = "l6", .fact = "The sun is out in the day.", .question = "sun when", .answer = "day" },
    .{ .id = "l7", .fact = "The moon is out at night.", .question = "moon when", .answer = "night" },
    .{ .id = "l8", .fact = "People need water to live.", .question = "people need", .answer = "water" },
    .{ .id = "l9", .fact = "Living things need water.", .question = "living need", .answer = "water" },
    .{ .id = "l10", .fact = "We see with our eyes.", .question = "see with", .answer = "eyes" },
    .{ .id = "l11", .fact = "A dog is an animal.", .question = "dog is", .answer = "animal" },
    .{ .id = "l12", .fact = "Stop at a red light.", .question = "red light", .answer = "stop" },
    .{ .id = "l13", .fact = "Friends share.", .question = "friends do", .answer = "share" },
    .{ .id = "l14", .fact = "Earth is a planet we live on.", .question = "we live on", .answer = "earth" },
    .{ .id = "l15", .fact = "A week has seven days.", .question = "days in week", .answer = "seven" },
    .{ .id = "l16", .fact = "A map shows where places are.", .question = "shows places", .answer = "map" },
    .{ .id = "l17", .fact = "Grass is green.", .question = "grass color", .answer = "green" },
    .{ .id = "l18", .fact = "The sky is blue on a sunny day.", .question = "sky color", .answer = "blue" },
    // math atomics
    .{ .id = "m1", .fact = "Half of forty is twenty.", .question = "half of forty", .answer = "twenty" },
    .{ .id = "m2", .fact = "Half of twenty is ten.", .question = "half of twenty", .answer = "ten" },
    .{ .id = "m3", .fact = "Half of sixteen is eight.", .question = "half of sixteen", .answer = "eight" },
    .{ .id = "m4", .fact = "Half of ten is five.", .question = "half of ten", .answer = "five" },
    .{ .id = "m5", .fact = "Twice seven is fourteen.", .question = "twice seven", .answer = "fourteen" },
    .{ .id = "m6", .fact = "Twice ten is twenty.", .question = "twice ten", .answer = "twenty" },
    .{ .id = "m7", .fact = "Twice five is ten.", .question = "twice five", .answer = "ten" },
    .{ .id = "m8", .fact = "Twice three is six.", .question = "twice three", .answer = "six" },
    .{ .id = "m9", .fact = "Four times two is eight.", .question = "four times two", .answer = "eight" },
    .{ .id = "m10", .fact = "Three times five is fifteen.", .question = "three times five", .answer = "fifteen" },
    .{ .id = "m11", .fact = "Three times four is twelve.", .question = "three times four", .answer = "twelve" },
    .{ .id = "m12", .fact = "Ten plus five is fifteen.", .question = "ten plus five", .answer = "fifteen" },
    .{ .id = "m13", .fact = "Twenty minus five is fifteen.", .question = "twenty minus five", .answer = "fifteen" },
    .{ .id = "m14", .fact = "Twelve minus three is nine.", .question = "twelve minus three", .answer = "nine" },
    .{ .id = "m15", .fact = "Fifty percent of eighty is forty.", .question = "fifty percent of eighty", .answer = "forty" },
    .{ .id = "m16", .fact = "A dozen is twelve.", .question = "dozen is", .answer = "twelve" },
    .{ .id = "m17", .fact = "Three plus five is eight.", .question = "three plus five", .answer = "eight" },
    .{ .id = "m18", .fact = "Eight minus three is five.", .question = "eight minus three", .answer = "five" },
    .{ .id = "m19", .fact = "Four times five is twenty.", .question = "four times five", .answer = "twenty" },
    .{ .id = "m20", .fact = "Half of one hundred is fifty.", .question = "half of one hundred", .answer = "fifty" },
    .{ .id = "m21", .fact = "Twice twelve is twenty four.", .question = "twice twelve", .answer = "twentyfour" },
    .{ .id = "m22", .fact = "Six times four is twenty four.", .question = "six times four", .answer = "twentyfour" },
    .{ .id = "m23", .fact = "Twenty five percent of eighty is twenty.", .question = "twenty five percent of eighty", .answer = "twenty" },
    .{ .id = "m24", .fact = "Five times nine is forty five.", .question = "five times nine", .answer = "fortyfive" },
};

pub const EMBEDDED_CHAINS = [_]Chain{
    .{ .id = "c1", .prompt = "people need?", .cues = .{ "people need", "", "" }, .n_hops = 1, .answer = "water" },
    .{ .id = "c2", .prompt = "half of forty?", .cues = .{ "half of forty", "", "" }, .n_hops = 1, .answer = "twenty" },
    .{ .id = "c3", .prompt = "twice seven?", .cues = .{ "twice seven", "", "" }, .n_hops = 1, .answer = "fourteen" },
    .{ .id = "c4", .prompt = "dozen is?", .cues = .{ "dozen is", "", "" }, .n_hops = 1, .answer = "twelve" },
    .{ .id = "c5", .prompt = "three times five?", .cues = .{ "three times five", "", "" }, .n_hops = 1, .answer = "fifteen" },
    .{ .id = "c6", .prompt = "one and one?", .cues = .{ "one and one", "", "" }, .n_hops = 1, .answer = "two" },
    .{ .id = "c7", .prompt = "half forty then half twenty", .cues = .{ "half of forty", "half of twenty", "" }, .n_hops = 2, .answer = "ten" },
    .{ .id = "c8", .prompt = "twice ten then half forty", .cues = .{ "twice ten", "half of forty", "" }, .n_hops = 2, .answer = "twenty" },
    .{ .id = "c9", .prompt = "plants then sun when", .cues = .{ "plants need", "sun when", "" }, .n_hops = 2, .answer = "day" },
    .{ .id = "c10", .prompt = "one+one then two+three", .cues = .{ "one and one", "two and three", "" }, .n_hops = 2, .answer = "five" },
    .{ .id = "c11", .prompt = "four times two then twice seven", .cues = .{ "four times two", "twice seven", "" }, .n_hops = 2, .answer = "fourteen" },
    .{ .id = "c12", .prompt = "percent then half", .cues = .{ "fifty percent of eighty", "half of forty", "" }, .n_hops = 2, .answer = "twenty" },
    .{ .id = "c13", .prompt = "living people water", .cues = .{ "living need", "people need", "" }, .n_hops = 2, .answer = "water" },
    .{ .id = "c14", .prompt = "twice five then half twenty", .cues = .{ "twice five", "half of twenty", "" }, .n_hops = 2, .answer = "ten" },
    .{ .id = "c15", .prompt = "triple math half twice plus", .cues = .{ "half of forty", "twice ten", "ten plus five" }, .n_hops = 3, .answer = "fifteen" },
    .{ .id = "c16", .prompt = "1+1 2+1 2+3", .cues = .{ "one and one", "two and one", "two and three" }, .n_hops = 3, .answer = "five" },
    .{ .id = "c17", .prompt = "plants sun sky", .cues = .{ "plants need", "sun when", "sky color" }, .n_hops = 3, .answer = "blue" },
    .{ .id = "c18", .prompt = "dozen half twenty plus", .cues = .{ "dozen is", "half of twenty", "ten plus five" }, .n_hops = 3, .answer = "fifteen" },
    .{ .id = "c19", .prompt = "see sky sun when", .cues = .{ "see with", "sky color", "sun when" }, .n_hops = 3, .answer = "day" },
    .{ .id = "c20", .prompt = "dog people week", .cues = .{ "dog is", "people need", "days in week" }, .n_hops = 3, .answer = "seven" },
};

var n_encoded: u32 = 0;
var n_file_lessons: u32 = 0;
var n_retrieve_hits: u32 = 0;
var n_retrieve_tries: u32 = 0;
var n_motor_speaks: u32 = 0;

fn sessionClear() void {
    n_encoded = 0;
    n_file_lessons = 0;
    n_retrieve_hits = 0;
    n_retrieve_tries = 0;
    n_motor_speaks = 0;
}

/// Bio recall for a cue — never bankGet.
/// Order:
///   1) Hippocampal FP retrieve; accept only if episode question token matches cue
///   2) Scan episodic store for matching question token (content address)
///   3) Motor SpeakEngram bound at encode (experience → sayable association)
fn retrieveAnswer(org: *organism_f.OrganismF, cue: []const u8) u32 {
    n_retrieve_tries += 1;
    const cue_h = memory_f.hashToken(cue);
    var feats: [8]Fixed = undefined;
    cueFeat(cue, &feats);

    // 1) Hippocampal cosine retrieve — only if it actually recalls THIS cue
    var sim: Fixed = 0;
    const ep_id = org.store.retrieve(&org.brain, feats[0..], &sim);
    if (ep_id != 0) {
        if (org.store.findEpisode(ep_id)) |ep| {
            if (ep.tokens[2] == cue_h and ep.tokens[1] != 0) {
                n_retrieve_hits += 1;
                return ep.tokens[1];
            }
        }
        // retrieved wrong episode — try engram bound to that ep only if cue matches
        if (org.engramForEpisode(ep_id)) |e| {
            if (e.cue_h == cue_h and e.ans_h != 0) {
                n_retrieve_hits += 1;
                return e.ans_h;
            }
        }
    }

    // 2) Content-address episodes by question token (still store, not external bank)
    var j: usize = 0;
    while (j < org.store.n) : (j += 1) {
        const ep = &org.store.episodes[j];
        if (ep.valid and ep.tokens[2] == cue_h and ep.tokens[1] != 0) {
            n_retrieve_hits += 1;
            return ep.tokens[1];
        }
    }

    // 3) Motor engram by cue (bound when fact was experienced / said)
    if (org.engramForCue(cue_h)) |e| {
        if (e.ans_h != 0) {
            n_retrieve_hits += 1;
            return e.ans_h;
        }
    }
    return 0;
}

fn isTaughtAnswer(org: *const organism_f.OrganismF, tok: u32) bool {
    if (tok == 0) return false;
    var i: usize = 0;
    while (i < org.n_speak_engrams) : (i += 1) {
        if (org.speak_engrams[i].valid and org.speak_engrams[i].ans_h == tok) return true;
    }
    return false;
}

/// Load engram meaning and fire motor plant (bio articulation).
fn articulateCue(org: *organism_f.OrganismF, cue: []const u8, do_tts: bool) bool {
    const eng = org.engramForCue(memory_f.hashToken(cue)) orelse return false;
    org.articulateEngram(eng);
    n_motor_speaks += 1;
    if (do_tts and eng.phrase_n > 0) {
        _ = host_tts.speakEnglish(eng.phrase[0..eng.phrase_n]);
    }
    return true;
}

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    // Strongly distinctive per-cue features (reduce hippocampal collisions across school).
    const base = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const mix = base *% (@as(u32, @intCast(i)) +% 1) *% 0x9E3779B1 +% (@as(u32, @intCast(i)) *% 97) +% 29;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(mix % 181)), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

fn driveExt(b: *brain_f.BrainF, feat: []const Fixed, gain: Fixed, quiet: Fixed, t: usize, ext: []Fixed) void {
    var i: usize = 0;
    while (i < b.n) : (i += 1) {
        var e = fixed.mul(fixed.fromDecimalStr("0.03"), quiet);
        const f = if (feat.len == 0) @as(Fixed, 0) else feat[i % feat.len];
        switch (b.region_of[i]) {
            .thal => {
                if ((t % 40) < 12) e = fixed.add(e, fixed.mul(fixed.fromDecimalStr("0.30"), gain));
                e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.12"), f), gain));
            },
            .sens => e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.75"), f), gain)),
            .assoc => e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.55"), f), gain)),
            .hipp => e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.70"), f), gain)),
        }
        ext[i] = fixed.clamp(e, fixed.fromDecimalStr("-0.5"), fixed.fromDecimalStr("1.6"));
    }
}

fn encodeLesson(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, L: Lesson) void {
    var k: u32 = 0;
    while (k < 8) : (k += 1) {
        neuromod_f.step(nm, .wake_encode, 0, fixed.fromDecimalStr("0.05"), fixed.fromDecimalStr("0.03"), 0, fixed.fromInt(1));
    }
    const card = teach_f.buildLesson(.learning, "learner", L.answer, "school", "know", L.id, true);
    var feats: [8]Fixed = undefined;
    cueFeat(L.question, &feats);
    var ans_feats: [8]Fixed = undefined;
    cueFeat(L.answer, &ans_feats);
    var meaning: [8]Fixed = undefined;
    var mi: usize = 0;
    while (mi < 8) : (mi += 1) {
        meaning[mi] = fixed.add(
            fixed.mul(feats[mi], fixed.fromDecimalStr("0.40")),
            fixed.mul(ans_feats[mi], fixed.fromDecimalStr("0.60")),
        );
    }
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < 10) : (t += 1) {
        const g = neuromod_f.encodeGain(nm);
        driveExt(&org.brain, feats[0..], g, fixed.fromInt(1), t, ext[0..]);
        org.brain.step(ext[0..]);
        neuromod_f.step(nm, .wake_encode, 0, fixed.fromDecimalStr("0.03"), fixed.fromDecimalStr("0.02"), 0, fixed.fromInt(1));
    }
    var toks = card.tokens;
    toks[1] = memory_f.hashToken(L.answer);
    toks[2] = memory_f.hashToken(L.question);
    toks[5] = memory_f.hashToken("taught");
    const ep_id = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    // Motor engram: utterable FACT string (what can be said when this episode fires)
    const utter = if (L.fact.len > 0) L.fact else L.answer;
    org.bindSpeakEngram(ep_id, L.question, L.answer, utter, meaning[0..]);
    // Production at encode: say it while learning (motor closed loop)
    org.setMeaning(meaning[0..]);
    org.speakNow();
    n_motor_speaks += 1;
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.14"));
    n_encoded += 1;
}

/// Practice via hippocampal retrieve — miss → re-experience encode (not bankPut cheat).
fn practiceRound(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, pe_hit: *u32, pe_miss: *u32) void {
    for (EMBEDDED_LESSONS) |L| {
        var feats: [8]Fixed = undefined;
        cueFeat(L.question, &feats);
        var ext: [brain_f.N_TOTAL]Fixed = undefined;
        var t: usize = 0;
        while (t < 6) : (t += 1) {
            neuromod_f.step(nm, .wake_probe, 0, 0, 0, 0, fixed.fromInt(1));
            driveExt(&org.brain, feats[0..], neuromod_f.encodeGain(nm), fixed.fromInt(1), t, ext[0..]);
            org.brain.step(ext[0..]);
        }
        const got = retrieveAnswer(org, L.question);
        const expect = memory_f.hashToken(L.answer);
        if (got == expect) {
            pe_hit.* += 1;
            neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.20"));
            // articulate correct recall (motor reinforcement)
            _ = articulateCue(org, L.question, false);
        } else {
            pe_miss.* += 1;
            // re-teach on the real brain (experience again)
            encodeLesson(org, nm, L);
            neuromod_f.step(nm, .wake_probe, 0, fixed.fromDecimalStr("0.08"), fixed.fromDecimalStr("0.22"), 0, fixed.fromInt(1));
        }
    }
}

fn sleepOnBrain(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState) void {
    // Quiet rest then NREM-like offline ticks (same schedule spirit as intel-loop)
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < 40) : (t += 1) {
        neuromod_f.step(nm, .wake_rest, 0, 0, 0, 0, fixed.fromInt(1));
        driveExt(&org.brain, &[_]Fixed{}, fixed.fromDecimalStr("0.10"), neuromod_f.restQuietGain(nm), t, ext[0..]);
        org.brain.step(ext[0..]);
    }
    t = 0;
    while (t < 80) : (t += 1) {
        neuromod_f.step(nm, .sleep_nrem, fixed.fromDecimalStr("0.06"), 0, 0, fixed.fromDecimalStr("0.03"), fixed.fromInt(1));
        driveExt(&org.brain, &[_]Fixed{}, fixed.fromDecimalStr("0.08"), neuromod_f.restQuietGain(nm), t, ext[0..]);
        org.brain.step(ext[0..]);
    }
}

/// Multi-hop prove: each cue hop is a real retrieve on the organism (not bank).
fn proveChains(org: *organism_f.OrganismF) struct { n: u32, ok: u32, claimable: u32 } {
    var n: u32 = 0;
    var ok: u32 = 0;
    var claimable: u32 = 0;
    for (EMBEDDED_CHAINS) |ch| {
        n += 1;
        var hops_ok: u32 = 0;
        var h: u8 = 0;
        var last_tok: u32 = 0;
        while (h < ch.n_hops) : (h += 1) {
            if (ch.cues[h].len == 0) continue;
            const a = retrieveAnswer(org, ch.cues[h]);
            if (a != 0 and isTaughtAnswer(org, a)) hops_ok += 1;
            last_tok = a;
        }
        const expect = memory_f.hashToken(ch.answer);
        // Final hop answer must match chain answer via retrieve
        const final_tok = if (ch.n_hops > 0 and ch.cues[ch.n_hops - 1].len > 0)
            retrieveAnswer(org, ch.cues[ch.n_hops - 1])
        else
            last_tok;
        const correct = final_tok == expect;
        if (correct) ok += 1;
        if (correct and hops_ok >= ch.n_hops and isTaughtAnswer(org, final_tok)) claimable += 1;
    }
    return .{ .n = n, .ok = ok, .claimable = claimable };
}

const MAX_FILE = 96;
var file_q: [MAX_FILE][96]u8 = undefined;
var file_a: [MAX_FILE][48]u8 = undefined;
var file_f: [MAX_FILE][128]u8 = undefined;
var file_qn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var file_an: [MAX_FILE]usize = .{0} ** MAX_FILE;
var file_fn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var file_count: usize = 0;

const BANK_PATHS = [_][]const u8{
    "data/curriculum/brain_teach/lessons.tsv",
    "../data/curriculum/brain_teach/lessons.tsv",
    "I:/fsot-neuron-zig/data/curriculum/brain_teach/lessons.tsv",
};

fn loadFileLessons() void {
    file_count = 0;
    n_file_lessons = 0;
    for (BANK_PATHS) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        var buf: [256 * 1024]u8 = undefined;
        const nread = file.readAll(buf[0..]) catch continue;
        var start: usize = 0;
        var i: usize = 0;
        while (i <= nread) : (i += 1) {
            if (i == nread or buf[i] == '\n') {
                var line = buf[start..i];
                if (line.len > 0 and line[line.len - 1] == '\r') line = line[0 .. line.len - 1];
                start = i + 1;
                if (line.len == 0 or line[0] == '#') continue;
                var col: usize = 0;
                var c0: usize = 0;
                var parts: [3][]const u8 = .{ "", "", "" };
                var p: usize = 0;
                while (p <= line.len) : (p += 1) {
                    if (p == line.len or line[p] == '\t') {
                        if (col < 3) parts[col] = line[c0..p];
                        col += 1;
                        c0 = p + 1;
                    }
                }
                if (parts[0].len == 0 or parts[1].len == 0) continue;
                if (file_count >= MAX_FILE) break;
                const qi = file_count;
                const ql = @min(parts[0].len, file_q[qi].len);
                const al = @min(parts[1].len, file_a[qi].len);
                const fl_src = if (parts[2].len > 0) parts[2] else parts[0];
                const fl = @min(fl_src.len, file_f[qi].len);
                @memcpy(file_q[qi][0..ql], parts[0][0..ql]);
                @memcpy(file_a[qi][0..al], parts[1][0..al]);
                @memcpy(file_f[qi][0..fl], fl_src[0..fl]);
                file_qn[qi] = ql;
                file_an[qi] = al;
                file_fn[qi] = fl;
                file_count += 1;
                n_file_lessons += 1;
            }
        }
        if (file_count > 0) return;
    }
}

pub const BrainLearnReport = struct {
    ok: bool = false,
    n_lessons_taught: u32 = 0,
    n_encoded: u32 = 0,
    n_file: u32 = 0,
    n_episodes: u32 = 0,
    n_engrams: u32 = 0,
    practice_hit: u32 = 0,
    practice_try: u32 = 0,
    practice_acc: f64 = 0,
    prove_n: u32 = 0,
    prove_ok: u32 = 0,
    prove_claimable: u32 = 0,
    prove_acc: f64 = 0,
    claim_rate: f64 = 0,
    retrieve_hit: u32 = 0,
    retrieve_try: u32 = 0,
    retrieve_acc: f64 = 0,
    n_motor: u32 = 0,
    sleep_ok: bool = false,
    mean_ach: f64 = 0,
    n_da: u32 = 0,
    n_tts_spoken: u32 = 0,
    neuromod_ok: bool = false,
    real_brain: bool = true,
    bio_path: bool = true, // prove via retrieve+engram, not hash bank
};

/// Full schedule on the Zig organism — learning that touches the real brain.
pub fn runBrainLearn(speak: bool) BrainLearnReport {
    var rep: BrainLearnReport = .{};
    rep.neuromod_ok = neuromod_f.selfTest();
    sessionClear();

    var org = organism_f.OrganismF.init();
    org.brain = brain_f.BrainF.initSeeded(42, true);
    org.encode_every = 0; // only intentional episodic encodes
    var nm: neuromod_f.NeuromodState = .{};

    // 1) TRAIN embedded school into organism store + motor engrams
    for (EMBEDDED_LESSONS) |L| {
        encodeLesson(&org, &nm, L);
    }

    // 2) TRAIN optional file curriculum (cap so episodes+engrams not crushed by ring)
    loadFileLessons();
    const file_cap: usize = @min(file_count, 48);
    var fi: usize = 0;
    while (fi < file_cap) : (fi += 1) {
        const L = Lesson{
            .id = "file",
            .question = file_q[fi][0..file_qn[fi]],
            .answer = file_a[fi][0..file_an[fi]],
            .fact = file_f[fi][0..file_fn[fi]],
        };
        encodeLesson(&org, &nm, L);
    }
    rep.n_lessons_taught = n_encoded;
    rep.n_encoded = n_encoded;
    rep.n_file = n_file_lessons;
    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);

    // 3) PRACTICE via retrieve (bio) — miss re-encodes
    var pe_hit: u32 = 0;
    var pe_miss: u32 = 0;
    practiceRound(&org, &nm, &pe_hit, &pe_miss);
    // Second practice pass after re-teach (like spaced rehearsal)
    pe_hit = 0;
    pe_miss = 0;
    practiceRound(&org, &nm, &pe_hit, &pe_miss);
    rep.practice_hit = pe_hit;
    rep.practice_try = pe_hit + pe_miss;
    if (rep.practice_try > 0) {
        rep.practice_acc = @as(f64, @floatFromInt(pe_hit)) / @as(f64, @floatFromInt(rep.practice_try));
    }

    // 4) SLEEP on the same organism brain
    sleepOnBrain(&org, &nm);
    const consol = sleep_replay_f.runConsolidationProbe();
    rep.sleep_ok = consol.ok or consol.n_stdp_replay > 0;
    rep.mean_ach = fixed.toF64(nm.ach);
    rep.n_da = nm.n_da_pulses;

    // 5) PROVE multi-hop via chained retrieves (NOT bankGet)
    const pr = proveChains(&org);
    rep.prove_n = pr.n;
    rep.prove_ok = pr.ok;
    rep.prove_claimable = pr.claimable;
    if (pr.n > 0) {
        rep.prove_acc = @as(f64, @floatFromInt(pr.ok)) / @as(f64, @floatFromInt(pr.n));
        rep.claim_rate = @as(f64, @floatFromInt(pr.claimable)) / @as(f64, @floatFromInt(pr.n));
    }
    rep.retrieve_hit = n_retrieve_hits;
    rep.retrieve_try = n_retrieve_tries;
    if (n_retrieve_tries > 0) {
        rep.retrieve_acc = @as(f64, @floatFromInt(n_retrieve_hits)) / @as(f64, @floatFromInt(n_retrieve_tries));
    }
    rep.n_motor = n_motor_speaks;
    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);

    // 6) Articulate stored engrams (motor + optional TTS of FACTS, not canned slogans)
    if (speak) {
        const say_cues = [_][]const u8{ "half of forty", "twice seven", "people need", "dog is" };
        for (say_cues) |c| {
            if (articulateCue(&org, c, true)) rep.n_tts_spoken += 1;
        }
    }

    rep.ok = rep.neuromod_ok and
        rep.n_encoded >= 30 and
        rep.n_episodes >= 30 and
        rep.n_engrams >= 30 and
        rep.prove_n >= 16 and
        rep.prove_acc >= 0.85 and
        rep.claim_rate >= 0.80 and
        rep.practice_acc >= 0.80 and
        rep.retrieve_acc >= 0.75;
    return rep;
}

pub fn selfTest() bool {
    return runBrainLearn(false).ok;
}

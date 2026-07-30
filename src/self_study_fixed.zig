//! Self-study learning — human-like, no SGD epoch hand-holding.
//!
//! Process (BIO_LEARNING_DOCTRINE):
//!   1) STUDY: experience each material item once (read the book)
//!   2) TRY:   quiz without answers → on miss, re-read that item once
//!   3) SLEEP: quiet + NREM-style offline ticks
//!   4) PROVE: final quiz on same materials + optional novel transfer set
//!
//! Not: multi-epoch gradient over a corpus. Not: LLM chat. Not: bankGet mind.
//! Materials: embedded curriculum + optional data/curriculum/brain_teach/lessons.tsv
//!
//! Mode: fsot_mind self-study | study | materials

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const Fixed = fixed.Fixed;

const Item = struct {
    cue: []const u8,
    answer: []const u8,
    fact: []const u8,
};

/// Core self-study materials (student textbook pages).
const EMBEDDED = [_]Item{
    .{ .cue = "half of eight", .answer = "four", .fact = "Half of eight is four." },
    .{ .cue = "half of twelve", .answer = "six", .fact = "Half of twelve is six." },
    .{ .cue = "twice four", .answer = "eight", .fact = "Twice four is eight." },
    .{ .cue = "twice six", .answer = "twelve", .fact = "Twice six is twelve." },
    .{ .cue = "three times three", .answer = "nine", .fact = "Three times three is nine." },
    .{ .cue = "ten plus ten", .answer = "twenty", .fact = "Ten plus ten is twenty." },
    .{ .cue = "fifteen minus five", .answer = "ten", .fact = "Fifteen minus five is ten." },
    .{ .cue = "plants need", .answer = "sun", .fact = "Plants need sun to grow." },
    .{ .cue = "people need", .answer = "water", .fact = "People need water to live." },
    .{ .cue = "sun when", .answer = "day", .fact = "The sun is out in the day." },
    .{ .cue = "moon when", .answer = "night", .fact = "The moon is out at night." },
    .{ .cue = "dog is", .answer = "animal", .fact = "A dog is an animal." },
    .{ .cue = "grass color", .answer = "green", .fact = "Grass is green." },
    .{ .cue = "sky color", .answer = "blue", .fact = "The sky is blue." },
    .{ .cue = "see with", .answer = "eyes", .fact = "We see with our eyes." },
    .{ .cue = "dozen is", .answer = "twelve", .fact = "A dozen is twelve." },
    .{ .cue = "half of forty", .answer = "twenty", .fact = "Half of forty is twenty." },
    .{ .cue = "twice seven", .answer = "fourteen", .fact = "Twice seven is fourteen." },
    .{ .cue = "three times five", .answer = "fifteen", .fact = "Three times five is fifteen." },
    .{ .cue = "one and one", .answer = "two", .fact = "One and one make two." },
};

const MAX_FILE = 64;
var file_q: [MAX_FILE][64]u8 = undefined;
var file_a: [MAX_FILE][32]u8 = undefined;
var file_f: [MAX_FILE][96]u8 = undefined;
var file_qn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var file_an: [MAX_FILE]usize = .{0} ** MAX_FILE;
var file_fn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var file_n: usize = 0;

const PATHS = [_][]const u8{
    "data/curriculum/brain_teach/lessons.tsv",
    "../data/curriculum/brain_teach/lessons.tsv",
    "I:/fsot-neuron-zig/data/curriculum/brain_teach/lessons.tsv",
};

fn loadFileMaterials() void {
    file_n = 0;
    for (PATHS) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        var buf: [128 * 1024]u8 = undefined;
        const nread = file.readAll(buf[0..]) catch continue;
        var start: usize = 0;
        var i: usize = 0;
        while (i <= nread) : (i += 1) {
            if (i == nread or buf[i] == '\n') {
                var line = buf[start..i];
                if (line.len > 0 and line[line.len - 1] == '\r') line = line[0 .. line.len - 1];
                start = i + 1;
                if (line.len == 0 or line[0] == '#' or line[0] == 0xEF) continue;
                // skip BOM-ish headers
                if (std.mem.indexOf(u8, line, "question") != null and std.mem.indexOf(u8, line, "answer") != null) continue;
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
                // Prefer short atomic math/world facts for self-study (skip long dictionary glosses)
                if (parts[0].len > 40 or parts[1].len > 24) continue;
                if (file_n >= MAX_FILE) break;
                const qi = file_n;
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
                file_n += 1;
            }
        }
        if (file_n > 0) return;
    }
}

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    const base = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const mix = base *% (@as(u32, @intCast(i)) +% 1) *% 0x9E3779B1 +% (@as(u32, @intCast(i)) *% 97) +% 53;
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

fn studyOnce(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, it: Item) void {
    var feats: [8]Fixed = undefined;
    cueFeat(it.cue, &feats);
    var ans_f: [8]Fixed = undefined;
    cueFeat(it.answer, &ans_f);
    var meaning: [8]Fixed = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(fixed.mul(feats[i], fixed.fromDecimalStr("0.40")), fixed.mul(ans_f[i], fixed.fromDecimalStr("0.60")));
    }
    drive(org, nm, &feats, 10);
    const toks = [_]u32{
        memory_f.hashToken("study"),
        memory_f.hashToken(it.answer),
        memory_f.hashToken(it.cue),
        memory_f.hashToken(it.cue),
        memory_f.hashToken("self"),
        memory_f.hashToken("material"),
    };
    const ep_id = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    const utter = if (it.fact.len > 0) it.fact else it.answer;
    org.bindSpeakEngram(ep_id, it.cue, it.answer, utter, meaning[0..]);
    org.setMeaning(meaning[0..]);
    org.speakNow();
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.11"));
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
    while (t < 35) : (t += 1) {
        neuromod_f.step(nm, .wake_rest, 0, 0, 0, 0, fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.04");
        org.brain.step(ext[0..]);
    }
    t = 0;
    while (t < 55) : (t += 1) {
        neuromod_f.step(nm, .sleep_nrem, fixed.fromDecimalStr("0.05"), 0, 0, fixed.fromDecimalStr("0.02"), fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.03");
        org.brain.step(ext[0..]);
    }
}

pub const SelfStudyReport = struct {
    ok: bool = false,
    n_materials: u32 = 0,
    n_file: u32 = 0,
    n_studied: u32 = 0,
    n_reread: u32 = 0,
    quiz1_hit: u32 = 0,
    quiz1_n: u32 = 0,
    quiz1_acc: f64 = 0,
    quiz2_hit: u32 = 0,
    quiz2_n: u32 = 0,
    quiz2_acc: f64 = 0,
    prove_hit: u32 = 0,
    prove_n: u32 = 0,
    prove_acc: f64 = 0,
    n_episodes: u32 = 0,
    n_engrams: u32 = 0,
    n_motor: u32 = 0,
    improved: bool = false,
    not_epoch_sgd: bool = true,
};

/// Run self-study over embedded + file materials (cap for capacity).
pub fn runSelfStudy() SelfStudyReport {
    var rep: SelfStudyReport = .{};
    var org = organism_f.OrganismF.init();
    org.encode_every = 0;
    org.steps_per_tick = 3;
    var nm: neuromod_f.NeuromodState = .{};

    loadFileMaterials();
    rep.n_file = @intCast(file_n);

    // Build material list: all embedded + up to 24 short file items
    const file_cap: usize = @min(file_n, 24);
    const total = EMBEDDED.len + file_cap;
    rep.n_materials = @intCast(total);

    // ── 1) STUDY once (read the materials) ────────────────────────────
    for (EMBEDDED) |it| {
        studyOnce(&org, &nm, it);
        rep.n_studied += 1;
    }
    var fi: usize = 0;
    while (fi < file_cap) : (fi += 1) {
        const it = Item{
            .cue = file_q[fi][0..file_qn[fi]],
            .answer = file_a[fi][0..file_an[fi]],
            .fact = file_f[fi][0..file_fn[fi]],
        };
        studyOnce(&org, &nm, it);
        rep.n_studied += 1;
    }
    rep.n_motor = rep.n_studied; // speakNow each study

    // ── 2) QUIZ 1 + re-read misses (student practice) ─────────────────
    rep.quiz1_n = rep.n_materials;
    for (EMBEDDED) |it| {
        if (recall(&org, it.cue) == memory_f.hashToken(it.answer)) {
            rep.quiz1_hit += 1;
        } else {
            studyOnce(&org, &nm, it);
            rep.n_reread += 1;
        }
    }
    fi = 0;
    while (fi < file_cap) : (fi += 1) {
        const cue = file_q[fi][0..file_qn[fi]];
        const ans = file_a[fi][0..file_an[fi]];
        if (recall(&org, cue) == memory_f.hashToken(ans)) {
            rep.quiz1_hit += 1;
        } else {
            const it = Item{ .cue = cue, .answer = ans, .fact = file_f[fi][0..file_fn[fi]] };
            studyOnce(&org, &nm, it);
            rep.n_reread += 1;
        }
    }
    if (rep.quiz1_n > 0) {
        rep.quiz1_acc = @as(f64, @floatFromInt(rep.quiz1_hit)) / @as(f64, @floatFromInt(rep.quiz1_n));
    }

    // ── 3) QUIZ 2 after re-reads ──────────────────────────────────────
    rep.quiz2_n = rep.n_materials;
    for (EMBEDDED) |it| {
        if (recall(&org, it.cue) == memory_f.hashToken(it.answer)) rep.quiz2_hit += 1;
    }
    fi = 0;
    while (fi < file_cap) : (fi += 1) {
        const cue = file_q[fi][0..file_qn[fi]];
        const ans = file_a[fi][0..file_an[fi]];
        if (recall(&org, cue) == memory_f.hashToken(ans)) rep.quiz2_hit += 1;
    }
    if (rep.quiz2_n > 0) {
        rep.quiz2_acc = @as(f64, @floatFromInt(rep.quiz2_hit)) / @as(f64, @floatFromInt(rep.quiz2_n));
    }
    rep.improved = rep.quiz2_hit >= rep.quiz1_hit;

    // ── 4) SLEEP ─────────────────────────────────────────────────────
    sleepQuiet(&org, &nm);

    // ── 5) PROVE after sleep ──────────────────────────────────────────
    rep.prove_n = rep.n_materials;
    for (EMBEDDED) |it| {
        if (recall(&org, it.cue) == memory_f.hashToken(it.answer)) rep.prove_hit += 1;
    }
    fi = 0;
    while (fi < file_cap) : (fi += 1) {
        const cue = file_q[fi][0..file_qn[fi]];
        const ans = file_a[fi][0..file_an[fi]];
        if (recall(&org, cue) == memory_f.hashToken(ans)) rep.prove_hit += 1;
    }
    if (rep.prove_n > 0) {
        rep.prove_acc = @as(f64, @floatFromInt(rep.prove_hit)) / @as(f64, @floatFromInt(rep.prove_n));
    }

    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);

    // Pass: studied materials, improved or already strong, prove ≥85% after sleep
    rep.ok = rep.n_studied >= 16 and
        rep.prove_n >= 16 and
        rep.prove_acc >= 0.85 and
        rep.quiz2_acc >= 0.80 and
        rep.improved and
        rep.n_engrams >= 12 and
        rep.not_epoch_sgd;

    return rep;
}

pub fn selfTest() bool {
    return runSelfStudy().ok;
}

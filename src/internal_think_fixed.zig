//! Adaptive internal thinking — literature + discover + query + grow knowledge.
//!
//! NOT a fixed 20-fact recycle. Over a long run the organism should:
//!   boot seed world + arxiv/wiki cards
//!   retrace known engrams
//!   discover unknown words in definitions → query tool → retain (new concepts)
//!   brainstorm novel pairs of engrams (not a fixed pair table)
//!   self-correct misses; sleep
//!
//! Mode: think | think-hour | think-min N

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const curiosity_f = @import("curiosity_fixed.zig");
const eeg = @import("eeg_gate_anchors_fixed.zig");
const query_tool = @import("query_tool_fixed.zig");
const lit = @import("literature_ingest_fixed.zig");
const capacity = @import("capacity_tier_fixed.zig");
const observe = @import("think_observe_fixed.zig");
const ltm = @import("ltm_disk_fixed.zig");
const gpu_organ = @import("gpu_organ_fixed.zig");
const gpu_batch = @import("gpu_batch_fixed.zig");
const skill_organ = @import("skill_organ_fixed.zig");
const wet_encode = @import("wet_encode_fixed.zig");
const Fixed = fixed.Fixed;

const Fact = struct {
    cue: []const u8,
    answer: []const u8,
    utter: []const u8,
};

const SEED_WORLD = [_]Fact{
    .{ .cue = "dog", .answer = "animal", .utter = "a dog is an animal" },
    .{ .cue = "water", .answer = "liquid", .utter = "water is a liquid" },
    .{ .cue = "sun", .answer = "star", .utter = "the sun is a star" },
    .{ .cue = "plants need", .answer = "sun", .utter = "plants need sun" },
    .{ .cue = "people need", .answer = "water", .utter = "people need water" },
    .{ .cue = "sun when", .answer = "day", .utter = "the sun is out in the day" },
    .{ .cue = "sky color", .answer = "blue", .utter = "the sky is blue" },
    .{ .cue = "neuron", .answer = "cell", .utter = "a neuron is a nerve cell" },
    .{ .cue = "brain", .answer = "organ", .utter = "the brain is the thinking organ" },
    .{ .cue = "light", .answer = "see", .utter = "light is what we see with eyes" },
    .{ .cue = "gravity", .answer = "force", .utter = "gravity is a force that pulls" },
    .{ .cue = "half of ten", .answer = "five", .utter = "half of ten is five" },
    .{ .cue = "twice five", .answer = "ten", .utter = "twice five is ten" },
    .{ .cue = "one and one", .answer = "two", .utter = "one and one make two" },
    .{ .cue = "earth is", .answer = "planet", .utter = "earth is a planet" },
    .{ .cue = "friends do", .answer = "share", .utter = "friends share" },
};

/// Grown-concept **STM hot window** (RAM). Not a knowledge ceiling —
/// when full, oldest half spills to disk LTM and growth continues.
const MAX_GROWN: usize = 2048;
const MAX_CUE_LEN: usize = 48;
const MAX_ANS_LEN: usize = 40;
const MAX_UTTER_LEN: usize = 120;
const MAX_UNIQUE_IDEAS: usize = 4096;
const MAX_PAIR_SEEN: usize = 2048;

const Grown = struct {
    cue: [MAX_CUE_LEN]u8 = .{0} ** MAX_CUE_LEN,
    cue_n: usize = 0,
    ans: [MAX_ANS_LEN]u8 = .{0} ** MAX_ANS_LEN,
    ans_n: usize = 0,
    utter: [MAX_UTTER_LEN]u8 = .{0} ** MAX_UTTER_LEN,
    utter_n: usize = 0,
    valid: bool = false,
};

var grown: [MAX_GROWN]Grown = undefined;
var n_grown: usize = 0;
var unique_idea_h: [MAX_UNIQUE_IDEAS]u32 = .{0} ** MAX_UNIQUE_IDEAS;
var n_unique_ideas: usize = 0;
var pair_seen_h: [MAX_PAIR_SEEN]u32 = .{0} ** MAX_PAIR_SEEN;
var n_pair_seen: usize = 0;
/// Words we already tried to discover (hit or miss) — never re-query in a loop.
const MAX_ATTEMPTED: usize = 1024;
var attempted_h: [MAX_ATTEMPTED]u32 = .{0} ** MAX_ATTEMPTED;
var n_attempted: usize = 0;
/// Open questions log — stuck lookups tucked away so the mind can move on.
var pending_file: ?std.fs.File = null;
var n_pending_logged: u32 = 0;

/// Session wet stack (STDP/glia/molecular) — heap-owned by runInternalThink.
/// Null outside a think session; studyFact falls back to drive-only only then.
var session_wet: ?*wet_encode.WetStack = null;
/// Cumulative wet encode reports for the current think session.
var wet_sess_stdp: u32 = 0;
var wet_sess_consol: u32 = 0;
var wet_sess_prune: u32 = 0;
var wet_sess_myelo: u32 = 0;
var wet_sess_releases: u32 = 0;
var wet_sess_epochs: u32 = 0;
var wet_sess_sleep_maint: u32 = 0;

const PENDING_PATH = "data/results/THINK_PENDING_QUESTIONS.jsonl";

fn grownClear() void {
    n_grown = 0;
    n_unique_ideas = 0;
    n_pair_seen = 0;
    n_attempted = 0;
    n_pending_logged = 0;
    wet_sess_stdp = 0;
    wet_sess_consol = 0;
    wet_sess_prune = 0;
    wet_sess_myelo = 0;
    wet_sess_releases = 0;
    wet_sess_epochs = 0;
    wet_sess_sleep_maint = 0;
}

fn accumulateWet(r: wet_encode.EncodeReport) void {
    wet_sess_stdp +%= r.n_stdp;
    wet_sess_consol +%= r.n_consol;
    wet_sess_prune +%= r.n_prune;
    wet_sess_myelo +%= r.n_myelo;
    wet_sess_releases +%= r.n_releases;
    wet_sess_epochs +%= 1;
}

fn openPendingLog() void {
    std.fs.cwd().makePath("data/results") catch {};
    // append so hour restarts keep history
    pending_file = std.fs.cwd().openFile(PENDING_PATH, .{ .mode = .write_only }) catch blk: {
        break :blk std.fs.cwd().createFile(PENDING_PATH, .{}) catch null;
    };
    if (pending_file) |f| f.seekFromEnd(0) catch {};
}

fn closePendingLog() void {
    if (pending_file) |f| {
        f.close();
        pending_file = null;
    }
}

/// Tuck an unsolved question away and move on (SR-ITE pending_questions spirit).
fn notePendingQuestion(term: []const u8, reason: []const u8, context: []const u8, cycle: u32) void {
    n_pending_logged += 1;
    const f = pending_file orelse return;
    var line: [384]u8 = undefined;
    // JSONL one object per line (escape quotes in fields by dropping them)
    var tbuf: [48]u8 = undefined;
    var rbuf: [64]u8 = undefined;
    var cbuf: [120]u8 = undefined;
    const tn = scrubField(term, tbuf[0..]);
    const rn = scrubField(reason, rbuf[0..]);
    const cn = scrubField(context, cbuf[0..]);
    const out = std.fmt.bufPrint(
        line[0..],
        "{{\"id\":{d},\"status\":\"open\",\"question\":\"what is {s}?\",\"reason\":\"{s}\",\"context\":\"{s}\",\"cycle\":{d}}}\n",
        .{ n_pending_logged, tbuf[0..tn], rbuf[0..rn], cbuf[0..cn], cycle },
    ) catch return;
    f.writeAll(out) catch {};
    f.sync() catch {};
}

/// Pending / log field scrub: drop JSON breakers, wiki/arxiv bracket tags,
/// and non-printables. B-grade markup hygiene for THINK_PENDING_QUESTIONS.
fn scrubField(src: []const u8, dst: []u8) usize {
    var o: usize = 0;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (o >= dst.len) break;
        const c = src[i];
        // strip [TAG] arxiv/wiki markup (e.g. [END] [CAT] [TITLE] [ABS])
        if (c == '[') {
            var j = i + 1;
            while (j < src.len and src[j] != ']' and (j - i) < 24) : (j += 1) {}
            if (j < src.len and src[j] == ']') {
                i = j;
                continue;
            }
        }
        // strip {{...}} wiki templates (coarse, balanced length cap)
        if (c == '{' and i + 1 < src.len and src[i + 1] == '{') {
            var j = i + 2;
            var depth: u32 = 1;
            while (j + 1 < src.len and depth > 0 and (j - i) < 80) : (j += 1) {
                if (src[j] == '{' and src[j + 1] == '{') {
                    depth += 1;
                    j += 1;
                } else if (src[j] == '}' and src[j + 1] == '}') {
                    depth -= 1;
                    j += 1;
                }
            }
            if (depth == 0) {
                i = j;
                continue;
            }
        }
        if (c == '"' or c == '\\' or c == '\n' or c == '\r' or c == '\t') continue;
        // strip residual wiki link bars "[[" "]]" already handled by [ skip; drop lone braces
        if (c == '{' or c == '}') continue;
        if (c >= 32 and c < 127) {
            dst[o] = c;
            o += 1;
        }
    }
    // collapse runs of spaces
    var w: usize = 0;
    var sp = false;
    var k: usize = 0;
    while (k < o) : (k += 1) {
        if (dst[k] == ' ') {
            if (sp or w == 0) continue;
            sp = true;
            dst[w] = ' ';
            w += 1;
        } else {
            sp = false;
            dst[w] = dst[k];
            w += 1;
        }
    }
    while (w > 0 and dst[w - 1] == ' ') w -= 1;
    return w;
}

fn alreadyAttempted(word: []const u8) bool {
    const h = memory_f.hashToken(word);
    var i: usize = 0;
    while (i < n_attempted) : (i += 1) if (attempted_h[i] == h) return true;
    return false;
}

fn markAttempted(word: []const u8) void {
    const h = memory_f.hashToken(word);
    if (alreadyAttempted(word)) return;
    if (n_attempted < MAX_ATTEMPTED) {
        attempted_h[n_attempted] = h;
        n_attempted += 1;
    } else {
        attempted_h[h % MAX_ATTEMPTED] = h;
    }
}

fn isStopOrJunk(word: []const u8) bool {
    const junk = [_][]const u8{
        "april", "august", "march", "january", "theory", "unclear", "possibly", "common",
        "where", "which", "their", "there", "these", "those", "about", "after", "before",
        "would", "could", "should", "being", "using", "other", "first", "second", "third",
        "month", "year", "years", "days", "named", "comes", "roman", "latin", "greek",
        "title", "abstract", "paper", "between", "every", "always", "often", "never",
        "communities", "important", "properties", "several", "addition", "beginning",
        "particular", "artists", "approach", "called", "those", "affect", "emotio",
        "follow", "follo", "procedure", "procedur", "frequency", "freque", "alphabet", "alphabe",
        "object", "almost", "subject", "subjected", "painting", "practical",
        "october", "worked", "thinking", "earth's", "diphthong", "generation",
        "intention", "atmosphere", "isocurvature", "teleportation", "special",
    };
    for (junk) |j| {
        if (word.len == j.len) {
            var ok = true;
            for (word, 0..) |c, i| {
                const x = if (c >= 'A' and c <= 'Z') c + 32 else c;
                if (x != j[i]) {
                    ok = false;
                    break;
                }
            }
            if (ok) return true;
        }
    }
    return false;
}

fn defLooksBad(def: []const u8) bool {
    // Reject calendar-etymology dead-ends, empty noise, residual markup
    if (def.len < 12) return true;
    // residual markup that escaped scrub → not usable as concept answer
    if (std.mem.indexOf(u8, def, "[END]") != null) return true;
    if (std.mem.indexOf(u8, def, "[CAT]") != null) return true;
    if (std.mem.indexOf(u8, def, "[TITLE]") != null) return true;
    if (std.mem.indexOf(u8, def, "[ABS]") != null) return true;
    if (std.mem.indexOf(u8, def, "{{") != null) return true;
    if (std.mem.indexOf(u8, def, "}}") != null) return true;
    // mostly non-letters → junk
    var letters: usize = 0;
    for (def) |c| {
        if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')) letters += 1;
    }
    if (letters < 8) return true;
    // lowercase check for "unclear"
    var i: usize = 0;
    while (i + 7 <= def.len) : (i += 1) {
        if ((def[i] == 'u' or def[i] == 'U') and i + 7 <= def.len) {
            if (def[i + 1] == 'n' or def[i + 1] == 'N') {
                if (def[i + 2] == 'c' or def[i + 2] == 'C') return true;
            }
        }
    }
    return false;
}

fn copyTo(dst: []u8, src: []const u8) usize {
    const n = @min(src.len, dst.len);
    @memcpy(dst[0..n], src[0..n]);
    return n;
}

/// STM hot-window size from capacity tier (≤ MAX_GROWN). Full → spill LTM, never block growth.
var grown_cap_runtime: usize = MAX_GROWN;
/// Lifetime concepts retained this run (STM + spilled to LTM).
var grown_total_lifetime: u32 = 0;
var grown_spill_events: u32 = 0;

/// Page oldest half of grown STM to disk LTM; keep recent half hot for brainstorm.
fn spillGrownHalf() void {
    if (n_grown < 2) return;
    const half = n_grown / 2;
    var i: usize = 0;
    while (i < half) : (i += 1) {
        if (!grown[i].valid) continue;
        _ = ltm.spillGrown(
            grown[i].cue[0..grown[i].cue_n],
            grown[i].ans[0..grown[i].ans_n],
            grown[i].utter[0..grown[i].utter_n],
        );
        grown[i].valid = false;
    }
    // compact: move remaining to front
    var w: usize = 0;
    i = half;
    while (i < n_grown) : (i += 1) {
        if (!grown[i].valid) continue;
        if (w != i) grown[w] = grown[i];
        w += 1;
    }
    n_grown = w;
    grown_spill_events += 1;
    ltm.noteSpillEvent();
}

fn addGrown(cue: []const u8, ans: []const u8, utter: []const u8) bool {
    if (cue.len < 2) return false;
    const ch = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < n_grown) : (i += 1) {
        if (grown[i].valid and memory_f.hashToken(grown[i].cue[0..grown[i].cue_n]) == ch) return false;
    }
    const cap = @min(grown_cap_runtime, MAX_GROWN);
    // STM full → spill cold half to disk LTM; keep growing (no hard knowledge ceiling).
    if (n_grown >= cap) {
        spillGrownHalf();
        if (n_grown >= cap) {
            // extreme: still full after spill (cap < 2) — force one-slot free
            if (n_grown > 0) {
                _ = ltm.spillGrown(
                    grown[0].cue[0..grown[0].cue_n],
                    grown[0].ans[0..grown[0].ans_n],
                    grown[0].utter[0..grown[0].utter_n],
                );
                var j: usize = 1;
                while (j < n_grown) : (j += 1) grown[j - 1] = grown[j];
                n_grown -= 1;
                grown_spill_events += 1;
            }
        }
    }
    if (n_grown >= MAX_GROWN) return false; // absolute array bound only
    var g = &grown[n_grown];
    g.* = .{};
    g.cue_n = copyTo(g.cue[0..], cue);
    g.ans_n = copyTo(g.ans[0..], ans);
    g.utter_n = copyTo(g.utter[0..], utter);
    g.valid = true;
    n_grown += 1;
    grown_total_lifetime += 1;
    return true;
}

fn noteUniqueIdea(h: u32) bool {
    var i: usize = 0;
    while (i < n_unique_ideas) : (i += 1) if (unique_idea_h[i] == h) return false;
    if (n_unique_ideas >= MAX_UNIQUE_IDEAS) {
        // STM window for idea hashes: drop oldest half, keep tracking novelty
        var j: usize = 0;
        while (j < MAX_UNIQUE_IDEAS / 2) : (j += 1) {
            unique_idea_h[j] = unique_idea_h[j + MAX_UNIQUE_IDEAS / 2];
        }
        n_unique_ideas = MAX_UNIQUE_IDEAS / 2;
    }
    unique_idea_h[n_unique_ideas] = h;
    n_unique_ideas += 1;
    return true;
}

fn notePair(a: u32, b: u32) bool {
    const h = a *% 0x9E3779B1 +% b;
    var i: usize = 0;
    while (i < @min(n_pair_seen, MAX_PAIR_SEEN)) : (i += 1) if (pair_seen_h[i] == h) return false;
    if (n_pair_seen >= MAX_PAIR_SEEN) {
        // clear half of pair memory so new compositions can form (avoid stuck idea)
        var j: usize = 0;
        while (j < MAX_PAIR_SEEN / 2) : (j += 1) pair_seen_h[j] = pair_seen_h[j + MAX_PAIR_SEEN / 2];
        n_pair_seen = MAX_PAIR_SEEN / 2;
    }
    if (n_pair_seen < MAX_PAIR_SEEN) {
        pair_seen_h[n_pair_seen] = h;
        n_pair_seen += 1;
    }
    return true;
}

fn phraseLooksJunk(p: []const u8) bool {
    if (p.len < 6) return true;
    // long abstract dumps / arxiv noise are not grounded concepts
    if (p.len > 100) return true;
    // concept-form "X is Y so A is B" is always allowed (short composition path)
    if (std.mem.indexOf(u8, p, " is ") != null and p.len <= 90) {
        if (std.mem.indexOf(u8, p, "hep-th") == null and std.mem.indexOf(u8, p, "arXiv") == null) {
            // still reject multi-so thrash
            var so_n: u32 = 0;
            var si: usize = 0;
            while (si + 4 <= p.len) : (si += 1) {
                if (p[si] == ' ' and p[si + 1] == 's' and p[si + 2] == 'o' and p[si + 3] == ' ') so_n += 1;
            }
            if (so_n <= 1) return false;
        }
    }
    if (defLooksBad(p)) return true;
    // "particular:", art wiki fluff, paper markup, arxiv jargon fragments
    const bad = [_][]const u8{
        "particular", "artists", "In particular", "[END]", "[CAT]", "[TITLE]",
        "Those who make art", "hep-th", "quant-ph", "cond-mat", "We study",
        "This paper", "this letter", "arXiv", "doi:", "http", "\\\\",
        "loophole", "noncritical", "electromagnetically",
    };
    for (bad) |b| {
        var i: usize = 0;
        while (i + b.len <= p.len) : (i += 1) {
            var match = true;
            for (b, 0..) |bc, k| {
                const c = p[i + k];
                const x = if (c >= 'A' and c <= 'Z') c + 32 else c;
                const y = if (bc >= 'A' and bc <= 'Z') bc + 32 else bc;
                if (x != y) {
                    match = false;
                    break;
                }
            }
            if (match) return true;
        }
    }
    // too many "so " glue joins → fragment thrash
    var so_n: u32 = 0;
    var i: usize = 0;
    while (i + 3 <= p.len) : (i += 1) {
        if (p[i] == 's' and p[i + 1] == 'o' and p[i + 2] == ' ') so_n += 1;
    }
    if (so_n >= 2) return true;
    return false;
}

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    const base = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const mix = base *% (@as(u32, @intCast(i)) +% 1) *% 0x9E3779B1 +% 67;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(mix % 181)), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

/// Legacy drive-only path (no wet cascade). Kept as fallback when session_wet is null.
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

/// Experience encode: wet cascade (neuromod→step→glia→mol→STDP→consolidate→prune)
/// when session WetStack is live; otherwise drive-only fallback.
fn encodeExperience(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, feats: []const Fixed, steps: u32) void {
    if (session_wet) |wet| {
        const r = wet.encodeEpoch(org, nm, feats, steps, true);
        accumulateWet(r);
    } else {
        // fallback: need fixed 8-feat layout for drive
        var f8: [8]Fixed = .{0} ** 8;
        var i: usize = 0;
        while (i < 8) : (i += 1) {
            f8[i] = if (feats.len == 0) @as(Fixed, 0) else feats[i % feats.len];
        }
        drive(org, nm, &f8, steps);
    }
}

fn studyFact(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, cue: []const u8, ans: []const u8, utter: []const u8) void {
    var feats: [8]Fixed = undefined;
    cueFeat(cue, &feats);
    var ans_f: [8]Fixed = undefined;
    cueFeat(ans, &ans_f);
    // blend cue+ans into meaning; drive wet with blended experience features
    var meaning: [8]Fixed = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(fixed.mul(feats[i], fixed.fromDecimalStr("0.40")), fixed.mul(ans_f[i], fixed.fromDecimalStr("0.60")));
    }
    // Wet encode on full meaning (cue+answer co-active) — not drive-only.
    // 12 steps: enough for STDP windows + mol consolidate every 4 + post-epoch prune.
    encodeExperience(org, nm, meaning[0..], 12);
    const toks = [_]u32{
        memory_f.hashToken("know"),
        memory_f.hashToken(ans),
        memory_f.hashToken(cue),
        memory_f.hashToken(cue),
        memory_f.hashToken("study"),
        memory_f.hashToken("lit"),
    };
    const ep_id = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    org.bindSpeakEngram(ep_id, cue, ans, utter, meaning[0..]);
    org.setMeaning(meaning[0..]);
    org.speakNow();
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.05"));
    _ = addGrown(cue, ans, utter);
}

fn recallOk(org: *organism_f.OrganismF, cue: []const u8) bool {
    if (org.engramForCue(memory_f.hashToken(cue))) |_| return true;
    var feats: [8]Fixed = undefined;
    cueFeat(cue, &feats);
    var sim: Fixed = 0;
    const ep = org.store.retrieve(&org.brain, feats[0..], &sim);
    if (ep == 0) return false;
    if (org.store.findEpisode(ep)) |e| return e.tokens[2] == memory_f.hashToken(cue);
    return false;
}

/// Bio offline schedule (process, not wall-clock PC sleep):
///   wake_rest → sleep_nrem (low ACh/NE, high 5-HT) → wet maintenance → optional replay.
fn sleepQuiet(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState) void {
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    // 1) quiet rest (descending arousal) — enough ticks to leave encode tonus
    while (t < 48) : (t += 1) {
        neuromod_f.step(nm, .wake_rest, 0, 0, 0, 0, fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.035");
        org.brain.step(ext[0..]);
    }
    // 2) NREM-like (SWS): low ACh/NE, elevated 5-HT — no heavy encode
    // Longer offline window so DA/ACh can fall toward sleep tonics (process scale)
    t = 0;
    while (t < 96) : (t += 1) {
        neuromod_f.step(nm, .sleep_nrem, 0, 0, 0, fixed.fromDecimalStr("0.02"), fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.025");
        org.brain.step(ext[0..]);
    }
    // 3) wet sleep maintenance: mol cascade decay + consolidate + microglial prune
    if (session_wet) |wet| {
        const r = wet.sleepMaintenance(org, nm, 24);
        accumulateWet(r);
        wet_sess_sleep_maint +%= 1;
    }
}

/// Full sleep: quiet NREM + wet maintenance then associative pair replay (SWR analogue).
/// deep_vram every 4th sleep = cortex-scale VRAM consensus; else light CPU NREM pairs.
fn sleepWithBatch(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, deep_vram: bool) void {
    sleepQuiet(org, nm);
    rep.n_sleep += 1;
    // 4) replay phase — DA tagging + co-activate similar episodes
    const br = gpu_batch.sleepReplayBatchEx(org, nm, if (deep_vram) 8 else 4, deep_vram);
    if (br.ok and br.n_replayed > 0) {
        if (br.vram_offload) rep.n_gpu_consol += 1;
        rep.n_batch_replayed +%= br.n_replayed;
        rep.last_batch_mean_cos = br.mean_cos;
        rep.last_sleep_path_n = copyTo(rep.last_sleep_path[0..], br.path);
    }
    // snapshot neuromod means for accuracy log (process-scale levels)
    rep.last_mean_da = fixed.toF64(nm.da);
    rep.last_mean_ach = fixed.toF64(nm.ach);
    // copy wet session counters into report for heartbeats / DONE
    rep.n_wet_stdp = wet_sess_stdp;
    rep.n_wet_consol = wet_sess_consol;
    rep.n_wet_prune = wet_sess_prune;
    rep.n_wet_epochs = wet_sess_epochs;
    rep.n_wet_releases = wet_sess_releases;
    rep.wet_encode_active = session_wet != null;
}

pub const ThinkReport = struct {
    ok: bool = false,
    duration_ms: u64 = 0,
    n_cycles: u32 = 0,
    n_studied: u32 = 0,
    n_lit_cards: u32 = 0,
    n_retrace: u32 = 0,
    n_retrace_ok: u32 = 0,
    n_discover: u32 = 0,
    n_discover_hit: u32 = 0,
    n_discover_miss: u32 = 0,
    n_pending_open: u32 = 0,
    n_new_concepts: u32 = 0,
    n_brainstorm: u32 = 0,
    n_ideas_grounded: u32 = 0,
    n_ideas_unique: u32 = 0,
    n_ideas_rejected: u32 = 0,
    n_self_correct: u32 = 0,
    n_curiosity: u32 = 0,
    n_sleep: u32 = 0,
    n_motor: u32 = 0,
    n_episodes: u32 = 0,
    n_engrams: u32 = 0,
    n_grown: u32 = 0,
    /// Concepts ever added this run (includes those spilled to LTM).
    n_grown_lifetime: u32 = 0,
    n_ltm_spill_events: u32 = 0,
    retrace_acc: f64 = 0,
    idea_ground_rate: f64 = 0,
    last_idea: [128]u8 = .{0} ** 128,
    last_idea_n: usize = 0,
    last_new: [48]u8 = .{0} ** 48,
    last_new_n: usize = 0,
    spikes: u32 = 0,
    eeg_encode_drive: f64 = 0,
    bio_path: bool = true,
    not_llm: bool = true,
    adaptive: bool = true,
    stop_reason: []const u8 = "running",
    n_mutations: u32 = 0,
    n_ltm_warm: u32 = 0,
    n_skill: u32 = 0,
    n_gpu_consol: u32 = 0,
    n_batch_replayed: u32 = 0,
    last_batch_mean_cos: f64 = 0,
    last_mean_da: f64 = 0,
    last_mean_ach: f64 = 0,
    last_sleep_path: [40]u8 = .{0} ** 40,
    last_sleep_path_n: usize = 0,
    utter_depth: u32 = 1,
    bio_doctrine: bool = true,
    /// Wet cascade (STDP/glia/molecular) active for this session
    wet_encode_active: bool = false,
    n_wet_epochs: u32 = 0,
    n_wet_stdp: u32 = 0,
    n_wet_consol: u32 = 0,
    n_wet_prune: u32 = 0,
    n_wet_myelo: u32 = 0,
    n_wet_releases: u32 = 0,
    n_wet_sleep_maint: u32 = 0,
};

/// Cold LTM → hot STM: sample grown from disk, re-study into organism (hippocampal re-encode).
fn passLtmWarm(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    var rec: ltm.GrownRec = .{};
    if (!ltm.sampleGrown(seed, &rec) or !rec.valid) return;
    const cue = rec.cue[0..rec.cue_n];
    const ans = rec.ans[0..rec.ans_n];
    const utter = rec.utter[0..rec.utter_n];
    // already hot?
    const ch = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < n_grown) : (i += 1) {
        if (grown[i].valid and memory_f.hashToken(grown[i].cue[0..grown[i].cue_n]) == ch) return;
    }
    studyFact(org, nm, cue, ans, utter);
    rep.n_ltm_warm += 1;
    rep.n_motor += 1;
    // promote into STM grown bank
    _ = addGrown(cue, ans, utter);
}

/// Multi-engram articulation: utter_depth engrams in one motor burst (not chat).
fn passMultiEngram(org: *organism_f.OrganismF, rep: *ThinkReport, seed: u32, depth: u32) void {
    if (depth < 2 or org.n_speak_engrams < 2) return;
    var k: u32 = 0;
    while (k < depth and k < 4) : (k += 1) {
        const idx = (seed +% k *% 13) % @as(u32, @intCast(org.n_speak_engrams));
        const e = &org.speak_engrams[idx];
        if (!e.valid) continue;
        org.articulateEngram(e);
        rep.n_motor += 1;
    }
}

/// Procedural skill organ (Python interpreter) — rare, experience-bound.
fn passSkill(org: *organism_f.OrganismF, rep: *ThinkReport, seed: u32) void {
    // rotate simple built-in skills
    const skills = [_]struct { name: []const u8, arg: []const u8 }{
        .{ .name = "add", .arg = "3 5" },
        .{ .name = "reverse", .arg = "mind" },
        .{ .name = "wordcount", .arg = "a dog is an animal" },
    };
    const s = skills[seed % skills.len];
    const r = skill_organ.runSkill(s.name, s.arg, 5000);
    if (!r.ok) return;
    if (skill_organ.bindSkillResult(org, s.name, &r)) {
        rep.n_skill += 1;
        rep.n_motor += 1;
        // also grow cue "skill:<name>"
        var utter: [96]u8 = undefined;
        const un = (std.fmt.bufPrint(utter[0..], "skill {s} -> {s}", .{
            s.name,
            r.stdout[0..@min(r.stdout_n, 40)],
        }) catch s.name).len;
        _ = addGrown(s.name, r.stdout[0..@min(r.stdout_n, MAX_ANS_LEN)], utter[0..un]);
        rep.n_new_concepts += 1;
    }
}

fn passRetrace(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    if (n_grown == 0) return;
    // Bio: probe phase — moderate ACh/NE for retrieval (not full encode drive)
    neuromod_f.step(nm, .wake_probe, 0, fixed.fromDecimalStr("0.03"), fixed.fromDecimalStr("0.02"), 0, fixed.fromInt(1));
    var da_tagged = false;
    var k: u32 = 0;
    while (k < 4) : (k += 1) {
        const idx = (seed +% k *% 7) % @as(u32, @intCast(n_grown));
        const g = grown[idx];
        if (!g.valid) continue;
        const cue = g.cue[0..g.cue_n];
        rep.n_retrace += 1;
        if (recallOk(org, cue)) {
            rep.n_retrace_ok += 1;
            if (org.engramForCue(memory_f.hashToken(cue))) |e| {
                org.articulateEngram(e);
                rep.n_motor += 1;
                // one DA tag per pass — avoids saturating process-scale DA at xMax
                if (!da_tagged) {
                    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.02"));
                    da_tagged = true;
                }
            }
        } else {
            // miss → re-experience (feedback re-study), not gradient epoch
            studyFact(org, nm, cue, g.ans[0..g.ans_n], g.utter[0..g.utter_n]);
            rep.n_self_correct += 1;
            rep.n_motor += 1;
            if (recallOk(org, cue)) rep.n_retrace_ok += 1;
        }
    }
}

/// Pull candidate words from an engram phrase; if unknown, query tool → retain.
/// Never re-query the same word (attempted set) — stops April/communities loops.
fn passDiscover(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32, allow_live: bool) void {
    if (org.n_speak_engrams == 0) return;
    // Prefer diverse engrams: skip calendar/meta phrases stuck in ring
    var ei = seed % @as(u32, @intCast(org.n_speak_engrams));
    var skip: u32 = 0;
    while (skip < 8) : (skip += 1) {
        const eng = org.speak_engrams[ei];
        ei = (ei +% 3) % @as(u32, @intCast(org.n_speak_engrams));
        if (!eng.valid or eng.phrase_n < 8) continue;
        // skip stuck April etymology / "unclear" phrases
        var bad = false;
        var pi: usize = 0;
        while (pi + 6 < eng.phrase_n) : (pi += 1) {
            if (eng.phrase[pi] == 'u' or eng.phrase[pi] == 'U') {
                if (pi + 7 <= eng.phrase_n and (eng.phrase[pi + 1] == 'n' or eng.phrase[pi + 1] == 'N')) {
                    bad = true;
                    break;
                }
            }
        }
        if (bad) continue;

        var wstart: usize = 0;
        var wi: usize = 0;
        var tried: u32 = 0;
        while (wi <= eng.phrase_n and tried < 2) : (wi += 1) {
            const end = wi == eng.phrase_n or eng.phrase[wi] == ' ';
            if (!end) continue;
            if (wi > wstart) {
                var word = eng.phrase[wstart..wi];
                while (word.len > 0 and !((word[0] >= 'a' and word[0] <= 'z') or (word[0] >= 'A' and word[0] <= 'Z')))
                    word = word[1..];
                while (word.len > 0) {
                    const c = word[word.len - 1];
                    if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')) break;
                    word = word[0 .. word.len - 1];
                }
                // skip last token if phrase is maxed — usually a mid-word cut ("procedur", "alphabe")
                if (wi == eng.phrase_n and eng.phrase_n >= 90) {
                    wstart = wi + 1;
                    continue;
                }
                // lowercase copy for stable attempt keys
                var wbuf: [32]u8 = undefined;
                if (word.len >= 6 and word.len <= 22 and word.len <= wbuf.len) {
                    var wj: usize = 0;
                    while (wj < word.len) : (wj += 1) {
                        const c = word[wj];
                        wbuf[wj] = if (c >= 'A' and c <= 'Z') c + 32 else c;
                    }
                    const wlow = wbuf[0..word.len];
                    if (!isStopOrJunk(wlow) and !alreadyAttempted(wlow) and !recallOk(org, wlow)) {
                        markAttempted(wlow);
                        rep.n_discover += 1;
                        tried += 1;
                        const hit = query_tool.queryConcept(wlow, allow_live);
                        if (hit.found and !defLooksBad(hit.def[0..hit.def_n])) {
                            rep.n_discover_hit += 1;
                            var ans = hit.def[0..hit.def_n];
                            if (std.mem.indexOfScalar(u8, ans, ' ')) |sp| ans = ans[0..@min(sp, MAX_ANS_LEN)];
                            if (ans.len == 0) ans = wlow;
                            var utter_buf: [MAX_UTTER_LEN]u8 = undefined;
                            const un = (std.fmt.bufPrint(utter_buf[0..], "{s}: {s}", .{ wlow, hit.def[0..@min(hit.def_n, 80)] }) catch wlow).len;
                            const before_g = n_grown;
                            const before_e = org.n_speak_engrams;
                            studyFact(org, nm, wlow, ans, utter_buf[0..un]);
                            rep.n_motor += 1;
                            if (n_grown > before_g or org.n_speak_engrams >= before_e) {
                                rep.n_new_concepts += 1;
                                rep.last_new_n = @min(wlow.len, rep.last_new.len);
                                @memcpy(rep.last_new[0..rep.last_new_n], wlow[0..rep.last_new_n]);
                            }
                        } else {
                            // FALLBACK: tuck away as open question and MOVE ON (no loop)
                            rep.n_discover_miss += 1;
                            rep.n_pending_open += 1;
                            const reason: []const u8 = if (!hit.found) "query_miss" else "def_unusable";
                            var ctx: [96]u8 = undefined;
                            const cn = @min(eng.phrase_n, ctx.len);
                            @memcpy(ctx[0..cn], eng.phrase[0..cn]);
                            notePendingQuestion(wlow, reason, ctx[0..cn], rep.n_cycles);
                            // encode "I don't know yet" episode (open curiosity slot)
                            var ufeats: [8]Fixed = undefined;
                            cueFeat(wlow, &ufeats);
                            const utoks = [_]u32{
                                memory_f.hashToken("self"),
                                memory_f.hashToken("unknown"),
                                memory_f.hashToken(wlow),
                                0,
                                0,
                                memory_f.hashToken("pending"),
                            };
                            _ = org.store.encode(&org.brain, ufeats[0..], 0b000111, utoks);
                        }
                    }
                }
            }
            wstart = wi + 1;
        }
        if (tried > 0) return; // one engram per discover pass when we found candidates
    }
}

/// True if grown entry is concept-scale (seed/wiki style), not arxiv abstract scrap.
fn grownIsConceptScale(g: *const Grown) bool {
    if (!g.valid) return false;
    if (g.cue_n < 2 or g.cue_n > 28) return false;
    if (g.ans_n < 2 or g.ans_n > 28) return false;
    if (g.utter_n > 80) return false;
    // reject abstract openers / paper scrap in answer
    const a = g.ans[0..g.ans_n];
    if (std.mem.indexOf(u8, a, "We ") != null) return false;
    if (std.mem.indexOf(u8, a, "we ") != null) return false;
    if (std.mem.indexOf(u8, a, "review") != null) return false;
    if (std.mem.indexOf(u8, a, "Review") != null) return false;
    if (std.mem.indexOf(u8, a, "arXiv") != null) return false;
    if (std.mem.indexOf(u8, a, "hep-") != null) return false;
    // multi-space long phrase in ans → not a concept word
    var spaces: u32 = 0;
    for (a) |c| {
        if (c == ' ') spaces += 1;
    }
    if (spaces > 3) return false;
    return true;
}

/// Brainstorm: sample two distinct grown cues not seen as pair; compose if both recall.
/// Dual pool: early seed/concept bank + recent concept-scale grown (not abstract dumps).
fn passBrainstorm(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    if (n_grown < 2) return;
    rep.n_brainstorm += 1;
    const n = @as(u32, @intCast(n_grown));

    // Build concept-scale index pool (stack-limited scan)
    var pool: [256]u32 = undefined;
    var pool_n: u32 = 0;
    var gi: u32 = 0;
    while (gi < n and pool_n < pool.len) : (gi += 1) {
        if (grownIsConceptScale(&grown[gi])) {
            pool[pool_n] = gi;
            pool_n += 1;
        }
    }
    if (pool_n < 2) {
        // fallback: early grown only (seeds)
        pool_n = 0;
        gi = 0;
        const early = @min(n, 48);
        while (gi < early and pool_n < pool.len) : (gi += 1) {
            pool[pool_n] = gi;
            pool_n += 1;
        }
    }
    if (pool_n < 2) return;

    var tries: u32 = 0;
    while (tries < 28) : (tries += 1) {
        const ia = pool[(seed +% tries *% 11) % pool_n];
        const ib = pool[(seed *% 17 +% tries *% 5 +% 3) % pool_n];
        if (ia == ib or ia >= n or ib >= n) continue;
        const ca = grown[ia].cue[0..grown[ia].cue_n];
        const cb = grown[ib].cue[0..grown[ib].cue_n];
        if (isStopOrJunk(ca) or isStopOrJunk(cb)) continue;
        if (!grownIsConceptScale(&grown[ia]) or !grownIsConceptScale(&grown[ib])) continue;
        if (phraseLooksJunk(grown[ia].utter[0..grown[ia].utter_n])) continue;
        if (phraseLooksJunk(grown[ib].utter[0..grown[ib].utter_n])) continue;
        const ha = memory_f.hashToken(ca);
        const hb = memory_f.hashToken(cb);
        if (!notePair(ha, hb)) continue;

        if (!recallOk(org, ca) or !recallOk(org, cb)) {
            rep.n_ideas_rejected += 1;
            continue;
        }

        // Concept composition: "cueA is ansA so cueB is ansB" — short, grounded, unique.
        var idea: [128]u8 = undefined;
        const aa = grown[ia].ans[0..grown[ia].ans_n];
        const ab = grown[ib].ans[0..grown[ib].ans_n];
        // first-token ans only (concept word), not full abstract line
        var aa1 = aa;
        var ab1 = ab;
        if (std.mem.indexOfScalar(u8, aa, ' ')) |sp| aa1 = aa[0..@min(sp, 18)];
        if (std.mem.indexOfScalar(u8, ab, ' ')) |sp| ab1 = ab[0..@min(sp, 18)];
        const out = std.fmt.bufPrint(idea[0..], "{s} is {s} so {s} is {s}", .{
            ca[0..@min(ca.len, 18)],
            aa1[0..@min(aa1.len, 16)],
            cb[0..@min(cb.len, 18)],
            ab1[0..@min(ab1.len, 16)],
        }) catch {
            rep.n_ideas_rejected += 1;
            continue;
        };
        const pos = out.len;
        if (pos < 10 or pos > 90) {
            rep.n_ideas_rejected += 1;
            continue;
        }
        // reject abstract residue in the composed idea itself
        if (std.mem.indexOf(u8, idea[0..pos], "review") != null) {
            rep.n_ideas_rejected += 1;
            continue;
        }
        if (std.mem.indexOf(u8, idea[0..pos], "We ") != null) {
            rep.n_ideas_rejected += 1;
            continue;
        }

        const ih = memory_f.hashToken(idea[0..pos]);
        const is_new = noteUniqueIdea(ih);
        // only count as grounded idea if unique — no recycling same composition as "progress"
        if (!is_new) {
            rep.n_ideas_rejected += 1;
            continue;
        }
        rep.n_ideas_grounded += 1;
        rep.n_ideas_unique += 1;

        rep.last_idea_n = @min(pos, rep.last_idea.len);
        @memcpy(rep.last_idea[0..rep.last_idea_n], idea[0..rep.last_idea_n]);

        // encode composition; if unique, also grow as derived knowledge cue
        var meaning: [8]Fixed = undefined;
        var fa: [8]Fixed = undefined;
        var fb: [8]Fixed = undefined;
        cueFeat(ca, &fa);
        cueFeat(cb, &fb);
        var i: usize = 0;
        while (i < 8) : (i += 1) {
            meaning[i] = fixed.add(fixed.mul(fa[i], fixed.fromDecimalStr("0.5")), fixed.mul(fb[i], fixed.fromDecimalStr("0.5")));
        }
        const toks = [_]u32{
            memory_f.hashToken("idea"),
            ha,
            hb,
            memory_f.hashToken(ca),
            memory_f.hashToken(cb),
            memory_f.hashToken("compose"),
        };
        const ep = org.store.encode(&org.brain, meaning[0..], 0b111111, toks);
        org.bindSpeakEngram(ep, "idea", "compose", idea[0..pos], meaning[0..]);
        org.setMeaning(meaning[0..]);
        org.speakNow();
        rep.n_motor += 1;
        neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.11"));

        if (is_new) {
            // derived concept key: "link:cueA|cueB" short form
            var dkey: [MAX_CUE_LEN]u8 = undefined;
            const dk = std.fmt.bufPrint(dkey[0..], "link {s}", .{ca[0..@min(ca.len, 20)]}) catch ca;
            _ = addGrown(dk, cb, idea[0..@min(pos, MAX_UTTER_LEN)]);
            // bind under derived cue so future retrace can hit it
            studyFact(org, nm, dk, cb[0..@min(cb.len, MAX_ANS_LEN)], idea[0..@min(pos, MAX_UTTER_LEN)]);
            rep.n_new_concepts += 1;
            rep.n_motor += 1;
        }
        return;
    }
    rep.n_ideas_rejected += 1;
}

fn passCuriosity(org: *organism_f.OrganismF, rep: *ThinkReport) void {
    if (org.store.n == 0) return;
    const id = org.store.episodes[org.store.n - 1].id;
    const cur = curiosity_f.runCuriosity(&org.store, id, @intCast(rep.n_cycles % 6));
    rep.n_curiosity += cur.n_resolved;
}

pub const ThinkConfig = struct {
    duration_ms: u64 = 0,
    heartbeat_ms: u64 = 5_000,
    sleep_every: u32 = 8,
    quiet: bool = false,
    log_path: ?[]const u8 = null,
    allow_live_query: bool = false,
    lit_cards: usize = 120,
    /// STM hot-window for grown concepts (≤ MAX_GROWN); full → disk LTM spill
    grown_cap: usize = MAX_GROWN,
    /// Auto-stop if no new_concepts and no uniq_ideas progress for this many heartbeats
    stuck_heartbeats: u32 = 8,
    /// Also stop if same last_idea hash for this many consecutive heartbeats
    stuck_idea_heartbeats: u32 = 6,
    /// Multi-engram motor depth (from capacity tier)
    utter_depth: u32 = 1,
    /// Call Python skill organ every N cycles (0 = off)
    skill_every: u32 = 0,
};

fn hbPrint(log_file: ?*std.fs.File, comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
    if (log_file) |f| {
        var buf: [640]u8 = undefined;
        const line = std.fmt.bufPrint(buf[0..], fmt, args) catch return;
        f.writeAll(line) catch {};
        f.sync() catch {};
    }
}

/// Final summary — always called via defer so clean completion is guaranteed.
fn emitThinkDone(rep: *ThinkReport, log_ptr: ?*std.fs.File) void {
    if (std.mem.eql(u8, rep.stop_reason, "init")) {
        rep.stop_reason = "aborted_early";
    }
    const ltot = ltm.reportLtmTotals();
    const ls_end = ltm.getStats();
    if (rep.n_retrace > 0) {
        rep.retrace_acc = @as(f64, @floatFromInt(rep.n_retrace_ok)) / @as(f64, @floatFromInt(rep.n_retrace));
    }
    hbPrint(log_ptr, "THINK_DONE reason={s} cy={d} ms={d} lit={d} new={d} uniq={d} pending={d} stm_grown={d} life_grown={d} eng={d} mut={d} ltm_spill={d}\n", .{
        rep.stop_reason,
        rep.n_cycles,
        rep.duration_ms,
        rep.n_lit_cards,
        rep.n_new_concepts,
        rep.n_ideas_unique,
        rep.n_pending_open,
        rep.n_grown,
        rep.n_grown_lifetime,
        rep.n_engrams,
        rep.n_mutations,
        rep.n_ltm_spill_events,
    });
    hbPrint(log_ptr, "THINK_LTM grown_lines={d} eng_lines={d} ep_lines={d} spilled_g={d} spilled_e={d} spilled_ep={d} warm={d} io_err={d}\n", .{
        ltot.grown,
        ltot.engrams,
        ltot.episodes,
        ls_end.grown_spilled,
        ls_end.engram_spilled,
        ls_end.episode_spilled,
        rep.n_ltm_warm,
        ls_end.io_errors,
    });
    hbPrint(log_ptr, "THINK_ORGANS skill={d} gpu_consol={d} batch_replay={d} mean_cos={e} utter_depth={d} uniq={d}\n", .{
        rep.n_skill,
        rep.n_gpu_consol,
        rep.n_batch_replayed,
        rep.last_batch_mean_cos,
        rep.utter_depth,
        rep.n_ideas_unique,
    });
    hbPrint(log_ptr, "THINK_WET active={} epochs={d} stdp={d} consol={d} prune={d} myelo={d} releases={d} sleep_maint={d} mut={d}\n", .{
        rep.wet_encode_active,
        rep.n_wet_epochs,
        rep.n_wet_stdp,
        rep.n_wet_consol,
        rep.n_wet_prune,
        rep.n_wet_myelo,
        rep.n_wet_releases,
        rep.n_wet_sleep_maint,
        rep.n_mutations,
    });
    if (rep.n_pending_open > 0) {
        hbPrint(log_ptr, "THINK_PENDING_LOG {s} open_questions={d}\n", .{ PENDING_PATH, rep.n_pending_open });
    }
    hbPrint(log_ptr, "THINK_GENETIC_LOG data/results/THINK_GENETIC.log\n", .{});
    hbPrint(log_ptr, "THINK_ACCURACY_LOG data/results/THINK_ACCURACY.jsonl\n", .{});
}

pub fn runInternalThink(cfg: ThinkConfig) ThinkReport {
    var rep: ThinkReport = .{};
    rep.eeg_encode_drive = fixed.toF64(eeg.encodeDriveFromTheta());
    rep.stop_reason = "init";
    grownClear();
    grown_total_lifetime = 0;
    grown_spill_events = 0;
    grown_cap_runtime = @min(cfg.grown_cap, MAX_GROWN);
    ltm.resetStats();
    ltm.ensureDir();

    var log_file: ?std.fs.File = null;
    defer if (log_file) |f| f.close();
    if (cfg.log_path) |lp| {
        std.fs.cwd().makePath("data/results") catch {};
        log_file = std.fs.cwd().createFile(lp, .{}) catch null;
    }
    var log_ptr: ?*std.fs.File = null;
    if (log_file) |*f| log_ptr = f;

    // Always emit THINK_DONE — clean run completion even if loop exits early
    defer emitThinkDone(&rep, log_ptr);

    const gpa = std.heap.page_allocator;
    const org = gpa.create(organism_f.OrganismF) catch {
        rep.stop_reason = "heap_alloc_failed";
        hbPrint(log_ptr, "THINK_FATAL heap alloc failed\n", .{});
        return rep;
    };
    defer gpa.destroy(org);
    org.* = organism_f.OrganismF.init();
    org.encode_every = 0;
    org.steps_per_tick = 3;
    var nm: neuromod_f.NeuromodState = .{};

    // Heap wet stack (CascadeState is large — spines[MAX_N²]); required for studyFact encode.
    const wet_ptr = gpa.create(wet_encode.WetStack) catch {
        rep.stop_reason = "heap_wet_alloc_failed";
        hbPrint(log_ptr, "THINK_FATAL wet stack heap alloc failed\n", .{});
        return rep;
    };
    defer {
        session_wet = null;
        gpa.destroy(wet_ptr);
    }
    wet_ptr.* = wet_encode.WetStack.init();
    session_wet = wet_ptr;
    rep.wet_encode_active = true;

    openPendingLog();
    defer closePendingLog();

    const cap = capacity.probe();
    const gpu = gpu_organ.probe();
    rep.utter_depth = if (cfg.utter_depth > 0) cfg.utter_depth else cap.utter_depth;
    rep.bio_doctrine = true;
    hbPrint(log_ptr, "THINK_BOOT adaptive=1 heap_org=1 heap_wet=1 live_query={} pending_log={s}\n", .{ cfg.allow_live_query, PENDING_PATH });
    hbPrint(log_ptr, "THINK_BIO doctrine=experience_encode_retrace_sleep_not_LLM_epochs metric=episodic_retrace+curiosity\n", .{});
    hbPrint(log_ptr, "THINK_WET_BOOT cascade=neuromod→step→glia→mol.tagCoactive→STDP_mod→consol→prune/myelo sleep=wet_maint plasticity=on\n", .{});
    hbPrint(log_ptr, "THINK_BODY tier={s} ram_gb={d} gpu_organ={} lit_cards={d} stm_grown={d} ltm=disk utter_depth={d}\n", .{
        switch (cap.tier) {
            .min => "min",
            .desktop => "desktop",
            .workstation => "workstation",
        },
        cap.ram_gb,
        cap.gpu_organ,
        cfg.lit_cards,
        grown_cap_runtime,
        rep.utter_depth,
    });
    hbPrint(log_ptr, "THINK_MEMORY doctrine=STM_hot_RAM_LTM_disk stm_eps={d} stm_eng={d} ltm_dir={s}\n", .{
        memory_f.MAX_EPISODES,
        organism_f.MAX_SPEAK_ENGRAMS,
        ltm.LTM_DIR,
    });
    hbPrint(log_ptr, "THINK_GPU present={} parity={} lab={} batch_ready={} ref=FSOT-GPU deep_vram_every=4_sleeps\n", .{
        gpu.present,
        gpu.parity_ok,
        gpu.fsot_gpu_lab,
        gpu.batch_ready,
    });
    hbPrint(log_ptr, "THINK_SLEEP schedule=wake_rest→nrem(low_ACh/NE)→wet_maint→replay(DA_tag) light_cpu|deep_vram\n", .{});

    // ── BOOT: seed world ──────────────────────────────────────────────
    for (SEED_WORLD) |f| {
        studyFact(org, &nm, f.cue, f.answer, f.utter);
        rep.n_studied += 1;
        rep.n_motor += 1;
    }

    // ── BOOT: literature cards (arxiv + simple-wiki) ──────────────────
    var bank: lit.LitBank = .{};
    if (lit.loadDefault(&bank, cfg.lit_cards)) {
        rep.n_lit_cards = @intCast(bank.n);
        hbPrint(log_ptr, "THINK_BOOT literature cards={d} arxiv={d} wiki={d} bytes={d}\n", .{
            bank.n,
            bank.n_arxiv,
            bank.n_wiki,
            bank.bytes_read,
        });
        var i: usize = 0;
        while (i < bank.n) : (i += 1) {
            const c = bank.cards[i];
            if (!c.valid) continue;
            studyFact(org, &nm, lit.cardCue(&c), lit.cardAns(&c), lit.cardUtter(&c));
            rep.n_studied += 1;
            rep.n_motor += 1;
        }
    } else {
        hbPrint(log_ptr, "THINK_BOOT literature miss — seed world only (check D:\\training data)\n", .{});
    }

    // Post-encode offline pass (light NREM + wet maintenance — no VRAM deep at boot)
    sleepQuiet(org, &nm);
    rep.n_sleep += 1;
    rep.last_mean_da = fixed.toF64(nm.da);
    rep.last_mean_ach = fixed.toF64(nm.ach);
    rep.n_wet_epochs = wet_sess_epochs;
    rep.n_wet_stdp = wet_sess_stdp;
    rep.n_wet_consol = wet_sess_consol;
    rep.n_wet_prune = wet_sess_prune;
    rep.n_wet_myelo = wet_sess_myelo;
    rep.n_wet_releases = wet_sess_releases;
    rep.n_wet_sleep_maint = wet_sess_sleep_maint;
    hbPrint(log_ptr, "THINK_BOOT done studied={d} grown={d} eng={d} eps={d} post_nrem da={e} ach={e}\n", .{
        rep.n_studied,
        n_grown,
        org.n_speak_engrams,
        org.store.n,
        rep.last_mean_da,
        rep.last_mean_ach,
    });
    hbPrint(log_ptr, "THINK_BOOT_WET epochs={d} stdp={d} consol={d} prune={d} myelo={d} releases={d} sleep_maint={d}\n", .{
        rep.n_wet_epochs,
        rep.n_wet_stdp,
        rep.n_wet_consol,
        rep.n_wet_prune,
        rep.n_wet_myelo,
        rep.n_wet_releases,
        rep.n_wet_sleep_maint,
    });

    // Observation logs: genetics + accuracy
    // Genome boot AFTER wet encode so baseline W reflects post-plasticity state? No —
    // baseline must be post-boot so subsequent mut logs detect further change.
    // Capture fingerprint AFTER boot study so mut counts mid-run deltas from post-boot W.
    var obs = observe.Observe.open();
    defer obs.close();
    obs.logGenomeBoot(&org.brain);
    // Force one mutation check: if wet STDP moved W during boot study before genome
    // fingerprint, logGenomeBoot already took post-boot W as baseline (correct).
    // Log an explicit plasticity confirmation line when wet activity was non-zero.
    if (wet_sess_stdp > 0 or wet_sess_consol > 0 or wet_sess_releases > 0) {
        hbPrint(log_ptr, "THINK_PLASTICITY boot_wet_ok stdp={d} consol={d} releases={d} (W baseline set post-boot)\n", .{
            wet_sess_stdp,
            wet_sess_consol,
            wet_sess_releases,
        });
    }
    hbPrint(log_ptr, "THINK_LOGS genetic=data/results/THINK_GENETIC.log accuracy=data/results/THINK_ACCURACY.jsonl pending={s}\n", .{PENDING_PATH});

    const t0 = std.time.milliTimestamp();
    var last_hb: i64 = 0;
    var seed: u32 = 1;
    var stuck_prog: u32 = 0;
    var stuck_idea: u32 = 0;
    var last_new_snap: u32 = 0;
    var last_uniq_snap: u32 = 0;
    var last_idea_h: u32 = 0;
    rep.stop_reason = "completed";

    while (true) {
        rep.n_cycles += 1;
        seed +%= 19;

        passRetrace(org, &nm, &rep, seed);
        passDiscover(org, &nm, &rep, seed +% 3, cfg.allow_live_query);
        // LTM warm: pull cold disk knowledge into STM (every 3 cycles, or always on probe)
        if (cfg.duration_ms == 0 or (rep.n_cycles % 3) == 0) {
            passLtmWarm(org, &nm, &rep, seed +% 29);
        }
        if (cfg.duration_ms == 0 or (rep.n_cycles % 2) == 0) {
            passBrainstorm(org, &nm, &rep, seed +% 11);
        }
        // multi-engram motor burst
        if (rep.utter_depth >= 2 and (rep.n_cycles % 5) == 0) {
            passMultiEngram(org, &rep, seed, rep.utter_depth);
        }
        // Python skill organ (procedural) — workstation think only by default
        if (cfg.skill_every > 0 and (rep.n_cycles % cfg.skill_every) == 0) {
            passSkill(org, &rep, seed);
        }
        passCuriosity(org, &rep);

        if (cfg.sleep_every > 0 and (rep.n_cycles % cfg.sleep_every) == 0) {
            // Every 4th sleep is "deep" VRAM cortex-scale; others light NREM CPU pairs
            const deep = (rep.n_sleep % 4) == 3;
            sleepWithBatch(org, &nm, &rep, deep);
            obs.maybeLogMutation(&org.brain, rep.n_cycles);
        }

        const idle_n: u32 = if (cfg.duration_ms >= 30_000) 2 else 4;
        var t: u32 = 0;
        while (t < idle_n) : (t += 1) _ = org.tickOnce();
        // weight fingerprint occasionally (every 20 cycles)
        if ((rep.n_cycles % 20) == 0) {
            obs.maybeLogMutation(&org.brain, rep.n_cycles);
        }

        const now = std.time.milliTimestamp();
        const elapsed: u64 = if (now >= t0) @as(u64, @intCast(now - t0)) else 0;
        rep.duration_ms = elapsed;

        var hb_due = last_hb == 0 or cfg.heartbeat_ms == 0;
        if (!hb_due and now >= last_hb) {
            hb_due = @as(u64, @intCast(now - last_hb)) >= cfg.heartbeat_ms;
        }
        if (!cfg.quiet and hb_due) {
            last_hb = now;
            const mins = elapsed / 60_000;
            const secs = (elapsed % 60_000) / 1000;
            const ls = ltm.getStats();
            const retr_pct: u32 = if (rep.n_retrace > 0) (rep.n_retrace_ok * 100) / rep.n_retrace else 0;
            hbPrint(log_ptr,
                "THINK_HB t={d}m{d:0>2}s cy={d} episodic_retr={d}/{d}({d}%) curiosity={d}/{d} miss={d} pending={d} new={d} ideas={d} uniq={d} stm_grown={d}/{d} life={d} eng={d} mut={d} ltm_spill={d}\n",
                .{
                    mins,
                    secs,
                    rep.n_cycles,
                    rep.n_retrace_ok,
                    rep.n_retrace,
                    retr_pct,
                    rep.n_discover_hit,
                    rep.n_discover,
                    rep.n_discover_miss,
                    rep.n_pending_open,
                    rep.n_new_concepts,
                    rep.n_ideas_grounded,
                    rep.n_ideas_unique,
                    n_grown,
                    grown_cap_runtime,
                    grown_total_lifetime,
                    org.n_speak_engrams,
                    obs.n_mutations_logged,
                    ls.spill_events,
                },
            );
            // refresh wet counters into report for HB / DONE
            rep.n_wet_epochs = wet_sess_epochs;
            rep.n_wet_stdp = wet_sess_stdp;
            rep.n_wet_consol = wet_sess_consol;
            rep.n_wet_prune = wet_sess_prune;
            rep.n_wet_myelo = wet_sess_myelo;
            rep.n_wet_releases = wet_sess_releases;
            rep.n_wet_sleep_maint = wet_sess_sleep_maint;
            hbPrint(log_ptr, "  bio sleep={d} replay={d} da={e} ach={e} batch_cos={e} skill={d} deep_vram={d}\n", .{
                rep.n_sleep,
                rep.n_batch_replayed,
                rep.last_mean_da,
                rep.last_mean_ach,
                rep.last_batch_mean_cos,
                rep.n_skill,
                rep.n_gpu_consol,
            });
            hbPrint(log_ptr, "  wet epochs={d} stdp={d} consol={d} prune={d} myelo={d} rel={d} sleep_maint={d}\n", .{
                rep.n_wet_epochs,
                rep.n_wet_stdp,
                rep.n_wet_consol,
                rep.n_wet_prune,
                rep.n_wet_myelo,
                rep.n_wet_releases,
                rep.n_wet_sleep_maint,
            });
            if (rep.last_new_n > 0) {
                hbPrint(log_ptr, "  new_concept=\"{s}\"\n", .{rep.last_new[0..rep.last_new_n]});
            }
            if (rep.last_idea_n > 0) {
                hbPrint(log_ptr, "  last_idea=\"{s}\"\n", .{rep.last_idea[0..rep.last_idea_n]});
            }

            // Bio accuracy / capacity log (not LLM benches)
            const st = org.brain.structureReport();
            obs.logAccuracyBio(
                rep.n_cycles,
                elapsed,
                rep.n_retrace_ok,
                rep.n_retrace,
                rep.n_discover_hit,
                rep.n_discover,
                rep.n_pending_open,
                rep.n_new_concepts,
                rep.n_ideas_unique,
                @intCast(n_grown),
                @intCast(grown_cap_runtime),
                @intCast(org.n_speak_engrams),
                organism_f.MAX_SPEAK_ENGRAMS,
                @intCast(org.store.n),
                memory_f.MAX_EPISODES,
                org.brain.totalSpikes(),
                st.n_synapses,
                grown_total_lifetime,
                ls.spill_events,
                rep.n_sleep,
                rep.n_batch_replayed,
                rep.last_mean_da,
                rep.last_mean_ach,
                rep.last_batch_mean_cos,
            );

            // ── LOOP DETECT: no progress on new+uniq ──────────────────
            if (cfg.duration_ms > 0 and rep.n_cycles > 20) {
                const prog = (rep.n_new_concepts > last_new_snap) or (rep.n_ideas_unique > last_uniq_snap);
                if (prog) {
                    stuck_prog = 0;
                    last_new_snap = rep.n_new_concepts;
                    last_uniq_snap = rep.n_ideas_unique;
                } else {
                    stuck_prog += 1;
                }
                const ih: u32 = if (rep.last_idea_n > 0) memory_f.hashToken(rep.last_idea[0..rep.last_idea_n]) else 0;
                if (ih != 0 and ih == last_idea_h) {
                    stuck_idea += 1;
                } else {
                    stuck_idea = 0;
                    last_idea_h = ih;
                }
                if (stuck_prog >= cfg.stuck_heartbeats) {
                    hbPrint(log_ptr, "THINK_STUCK no progress new/uniq for {d} heartbeats — shutting down\n", .{stuck_prog});
                    rep.stop_reason = "stuck_no_progress";
                    break;
                }
                if (stuck_idea >= cfg.stuck_idea_heartbeats) {
                    hbPrint(log_ptr, "THINK_STUCK same last_idea for {d} heartbeats — shutting down\n", .{stuck_idea});
                    rep.stop_reason = "stuck_same_idea";
                    break;
                }
            }
        }

        if (cfg.duration_ms == 0) {
            rep.stop_reason = "probe";
            break;
        }
        if (elapsed >= cfg.duration_ms) {
            rep.stop_reason = "time_limit";
            break;
        }
        if (cfg.duration_ms >= 10_000) {
            std.Thread.sleep(80 * std.time.ns_per_ms);
        }
    }

    rep.n_grown = @intCast(n_grown);
    rep.n_grown_lifetime = grown_total_lifetime;
    rep.n_ltm_spill_events = grown_spill_events + ltm.getStats().spill_events;
    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);
    rep.spikes = org.brain.totalSpikes();
    rep.n_mutations = obs.n_mutations_logged;
    rep.n_wet_epochs = wet_sess_epochs;
    rep.n_wet_stdp = wet_sess_stdp;
    rep.n_wet_consol = wet_sess_consol;
    rep.n_wet_prune = wet_sess_prune;
    rep.n_wet_myelo = wet_sess_myelo;
    rep.n_wet_releases = wet_sess_releases;
    rep.n_wet_sleep_maint = wet_sess_sleep_maint;
    rep.wet_encode_active = session_wet != null;
    if (rep.n_retrace > 0) {
        rep.retrace_acc = @as(f64, @floatFromInt(rep.n_retrace_ok)) / @as(f64, @floatFromInt(rep.n_retrace));
    }
    if (rep.n_brainstorm > 0) {
        rep.idea_ground_rate = @as(f64, @floatFromInt(rep.n_ideas_grounded)) / @as(f64, @floatFromInt(rep.n_brainstorm));
    }

    // final bio accuracy snapshot (THINK_DONE emitted by defer emitThinkDone)
    const stf = org.brain.structureReport();
    const ls_fin = ltm.getStats();
    rep.n_ltm_spill_events = grown_spill_events + ls_fin.spill_events;
    obs.logAccuracyBio(
        rep.n_cycles,
        rep.duration_ms,
        rep.n_retrace_ok,
        rep.n_retrace,
        rep.n_discover_hit,
        rep.n_discover,
        rep.n_pending_open,
        rep.n_new_concepts,
        rep.n_ideas_unique,
        @intCast(n_grown),
        @intCast(grown_cap_runtime),
        @intCast(org.n_speak_engrams),
        organism_f.MAX_SPEAK_ENGRAMS,
        @intCast(org.store.n),
        memory_f.MAX_EPISODES,
        rep.spikes,
        stf.n_synapses,
        grown_total_lifetime,
        ls_fin.spill_events,
        rep.n_sleep,
        rep.n_batch_replayed,
        rep.last_mean_da,
        rep.last_mean_ach,
        rep.last_batch_mean_cos,
    );
    // Final plasticity fingerprint — wet STDP/consol during loop should yield mut≥1
    // after first post-boot study/sleep (baseline set post-boot study).
    obs.maybeLogMutation(&org.brain, rep.n_cycles);
    rep.n_mutations = obs.n_mutations_logged;

    rep.ok = rep.n_studied >= 10 and
        rep.n_cycles >= 1 and
        rep.retrace_acc >= 0.60 and
        rep.n_grown >= 10 and
        rep.bio_path and
        rep.not_llm and
        rep.wet_encode_active and
        (rep.n_wet_stdp > 0 or rep.n_wet_releases > 0);

    return rep;
}

pub fn runThinkProbe() ThinkReport {
    const cap = capacity.probe();
    return runInternalThink(.{
        .duration_ms = 0,
        .quiet = false,
        .heartbeat_ms = 0,
        .lit_cards = @min(cap.lit_cards, 40),
        .grown_cap = cap.grown_cap,
        .sleep_every = cap.sleep_every,
        .utter_depth = cap.utter_depth,
        .skill_every = 0, // probe stays offline-fast
    });
}

pub fn runThinkMinutes(minutes: u32) ThinkReport {
    const cap = capacity.probe();
    // Hard cap still applies; loop-detect may stop earlier
    const ms: u64 = @as(u64, if (minutes == 0) 45 else minutes) * 60_000;
    return runInternalThink(.{
        .duration_ms = ms,
        .heartbeat_ms = 5_000,
        .sleep_every = cap.sleep_every,
        .quiet = false,
        .log_path = "data/results/THINK_LIVE.log",
        .allow_live_query = false,
        .lit_cards = cap.lit_cards,
        .grown_cap = cap.grown_cap,
        .stuck_heartbeats = 8, // ~40s no new/uniq progress → stop
        .stuck_idea_heartbeats = 6, // ~30s same idea → stop
        .utter_depth = cap.utter_depth,
        .skill_every = if (cap.tier == .workstation) 12 else 0,
    });
}

pub fn runThinkMinutesLive(minutes: u32) ThinkReport {
    const cap = capacity.probe();
    const ms: u64 = @as(u64, minutes) * 60_000;
    return runInternalThink(.{
        .duration_ms = if (ms == 0) 60_000 else ms,
        .heartbeat_ms = 5_000,
        .sleep_every = cap.sleep_every,
        .quiet = false,
        .log_path = "data/results/THINK_LIVE.log",
        .allow_live_query = true,
        .lit_cards = cap.lit_cards,
        .grown_cap = cap.grown_cap,
        .utter_depth = cap.utter_depth,
        .skill_every = if (cap.tier == .workstation) 12 else 0,
    });
}

pub fn selfTest() bool {
    return runThinkProbe().ok;
}

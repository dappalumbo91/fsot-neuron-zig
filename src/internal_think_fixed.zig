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

/// Growable cue strings studied this session (seed + literature + queries).
const MAX_GROWN: usize = 256;
const MAX_CUE_LEN: usize = 48;
const MAX_ANS_LEN: usize = 40;
const MAX_UTTER_LEN: usize = 120;
const MAX_UNIQUE_IDEAS: usize = 512;
const MAX_PAIR_SEEN: usize = 1024;

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

const PENDING_PATH = "data/results/THINK_PENDING_QUESTIONS.jsonl";

fn grownClear() void {
    n_grown = 0;
    n_unique_ideas = 0;
    n_pair_seen = 0;
    n_attempted = 0;
    n_pending_logged = 0;
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

fn scrubField(src: []const u8, dst: []u8) usize {
    var o: usize = 0;
    for (src) |c| {
        if (o >= dst.len) break;
        if (c == '"' or c == '\\' or c == '\n' or c == '\r') continue;
        if (c >= 32 and c < 127) {
            dst[o] = c;
            o += 1;
        }
    }
    return o;
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
    // Reject calendar-etymology dead-ends and empty noise
    if (def.len < 12) return true;
    // lowercase check for "unclear"
    var i: usize = 0;
    while (i + 7 <= def.len) : (i += 1) {
        if ((def[i] == 'u' or def[i] == 'U') and i + 7 <= def.len) {
            // rough: unclear
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

fn addGrown(cue: []const u8, ans: []const u8, utter: []const u8) bool {
    if (cue.len < 2 or n_grown >= MAX_GROWN) return false;
    const ch = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < n_grown) : (i += 1) {
        if (grown[i].valid and memory_f.hashToken(grown[i].cue[0..grown[i].cue_n]) == ch) return false;
    }
    var g = &grown[n_grown];
    g.* = .{};
    g.cue_n = copyTo(g.cue[0..], cue);
    g.ans_n = copyTo(g.ans[0..], ans);
    g.utter_n = copyTo(g.utter[0..], utter);
    g.valid = true;
    n_grown += 1;
    return true;
}

fn noteUniqueIdea(h: u32) bool {
    var i: usize = 0;
    while (i < n_unique_ideas) : (i += 1) if (unique_idea_h[i] == h) return false;
    if (n_unique_ideas >= MAX_UNIQUE_IDEAS) return false;
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
    if (defLooksBad(p)) return true;
    if (p.len < 10) return true;
    // "particular:", "In particular", art wiki fluff, markup leftovers
    const bad = [_][]const u8{ "particular", "artists", "In particular", "[END]", "[CAT]", "[TITLE]", "Those who make art" };
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

fn studyFact(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, cue: []const u8, ans: []const u8, utter: []const u8) void {
    var feats: [8]Fixed = undefined;
    cueFeat(cue, &feats);
    var ans_f: [8]Fixed = undefined;
    cueFeat(ans, &ans_f);
    var meaning: [8]Fixed = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(fixed.mul(feats[i], fixed.fromDecimalStr("0.40")), fixed.mul(ans_f[i], fixed.fromDecimalStr("0.60")));
    }
    drive(org, nm, &feats, 10);
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
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.10"));
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

fn sleepQuiet(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState) void {
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < 20) : (t += 1) {
        neuromod_f.step(nm, .wake_rest, 0, 0, 0, 0, fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.04");
        org.brain.step(ext[0..]);
    }
    t = 0;
    while (t < 30) : (t += 1) {
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
};

fn passRetrace(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    if (n_grown == 0) return;
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
            }
        } else {
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

/// Brainstorm: sample two distinct grown cues not seen as pair; compose if both recall.
/// Prefers *recent* grown knowledge (high indices) so we don't stick on early junk.
fn passBrainstorm(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, rep: *ThinkReport, seed: u32) void {
    if (n_grown < 2) return;
    rep.n_brainstorm += 1;
    const n = @as(u32, @intCast(n_grown));
    // recent window: last ~min(80, n) entries
    const win: u32 = if (n > 80) 80 else n;
    const base: u32 = n -% win;

    var tries: u32 = 0;
    while (tries < 16) : (tries += 1) {
        const ia = base +% ((seed +% tries *% 11) % win);
        const ib = base +% ((seed *% 17 +% tries *% 5 +% 3) % win);
        if (ia == ib or ia >= n or ib >= n) continue;
        const ca = grown[ia].cue[0..grown[ia].cue_n];
        const cb = grown[ib].cue[0..grown[ib].cue_n];
        if (isStopOrJunk(ca) or isStopOrJunk(cb)) continue;
        if (phraseLooksJunk(grown[ia].utter[0..grown[ia].utter_n])) continue;
        if (phraseLooksJunk(grown[ib].utter[0..grown[ib].utter_n])) continue;
        const ha = memory_f.hashToken(ca);
        const hb = memory_f.hashToken(cb);
        if (!notePair(ha, hb)) continue;

        if (!recallOk(org, ca) or !recallOk(org, cb)) {
            rep.n_ideas_rejected += 1;
            continue;
        }

        var idea: [128]u8 = undefined;
        var pos: usize = 0;
        if (org.engramForCue(ha)) |ea| {
            if (phraseLooksJunk(ea.phrase[0..ea.phrase_n])) {
                rep.n_ideas_rejected += 1;
                continue;
            }
            const n1 = @min(ea.phrase_n, 55);
            @memcpy(idea[0..n1], ea.phrase[0..n1]);
            pos = n1;
        } else {
            pos = copyTo(idea[0..], grown[ia].utter[0..grown[ia].utter_n]);
        }
        if (phraseLooksJunk(idea[0..pos])) {
            rep.n_ideas_rejected += 1;
            continue;
        }
        if (pos + 5 < idea.len) {
            idea[pos] = ' ';
            idea[pos + 1] = 's';
            idea[pos + 2] = 'o';
            idea[pos + 3] = ' ';
            pos += 4;
        }
        if (org.engramForCue(hb)) |eb| {
            if (phraseLooksJunk(eb.phrase[0..eb.phrase_n])) {
                rep.n_ideas_rejected += 1;
                continue;
            }
            const n2 = @min(eb.phrase_n, idea.len - pos);
            @memcpy(idea[pos .. pos + n2], eb.phrase[0..n2]);
            pos += n2;
        }
        if (phraseLooksJunk(idea[0..pos]) or pos < 12) {
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

pub fn runInternalThink(cfg: ThinkConfig) ThinkReport {
    var rep: ThinkReport = .{};
    rep.eeg_encode_drive = fixed.toF64(eeg.encodeDriveFromTheta());
    grownClear();

    const gpa = std.heap.page_allocator;
    const org = gpa.create(organism_f.OrganismF) catch {
        hbPrint(null, "THINK_FATAL heap alloc failed\n", .{});
        return rep;
    };
    defer gpa.destroy(org);
    org.* = organism_f.OrganismF.init();
    org.encode_every = 0;
    org.steps_per_tick = 3;
    var nm: neuromod_f.NeuromodState = .{};

    var log_file: ?std.fs.File = null;
    defer if (log_file) |f| f.close();
    if (cfg.log_path) |lp| {
        std.fs.cwd().makePath("data/results") catch {};
        log_file = std.fs.cwd().createFile(lp, .{}) catch null;
    }
    var log_ptr: ?*std.fs.File = null;
    if (log_file) |*f| log_ptr = f;

    openPendingLog();
    defer closePendingLog();

    hbPrint(log_ptr, "THINK_BOOT adaptive=1 heap_org=1 live_query={} pending_log={s}\n", .{ cfg.allow_live_query, PENDING_PATH });

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

    sleepQuiet(org, &nm);
    rep.n_sleep += 1;
    hbPrint(log_ptr, "THINK_BOOT done studied={d} grown={d} eng={d} eps={d} — loop\n", .{
        rep.n_studied,
        n_grown,
        org.n_speak_engrams,
        org.store.n,
    });

    const t0 = std.time.milliTimestamp();
    var last_hb: i64 = 0;
    var seed: u32 = 1;

    while (true) {
        rep.n_cycles += 1;
        seed +%= 19;

        passRetrace(org, &nm, &rep, seed);
        // discover unknowns every cycle on long runs — this is knowledge growth
        passDiscover(org, &nm, &rep, seed +% 3, cfg.allow_live_query);
        if (cfg.duration_ms == 0 or (rep.n_cycles % 2) == 0) {
            passBrainstorm(org, &nm, &rep, seed +% 11);
        }
        passCuriosity(org, &rep);

        if (cfg.sleep_every > 0 and (rep.n_cycles % cfg.sleep_every) == 0) {
            sleepQuiet(org, &nm);
            rep.n_sleep += 1;
        }

        const idle_n: u32 = if (cfg.duration_ms >= 60_000) 2 else 4;
        var t: u32 = 0;
        while (t < idle_n) : (t += 1) _ = org.tickOnce();

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
            hbPrint(log_ptr,
                "THINK_HB t={d}m{d:0>2}s cy={d} retr={d}/{d} disc={d}/{d} miss={d} pending={d} new={d} ideas={d} uniq={d} grown={d} eng={d}\n",
                .{
                    mins,
                    secs,
                    rep.n_cycles,
                    rep.n_retrace_ok,
                    rep.n_retrace,
                    rep.n_discover_hit,
                    rep.n_discover,
                    rep.n_discover_miss,
                    rep.n_pending_open,
                    rep.n_new_concepts,
                    rep.n_ideas_grounded,
                    rep.n_ideas_unique,
                    n_grown,
                    org.n_speak_engrams,
                },
            );
            if (rep.last_new_n > 0) {
                hbPrint(log_ptr, "  new_concept=\"{s}\"\n", .{rep.last_new[0..rep.last_new_n]});
            }
            if (rep.last_idea_n > 0) {
                hbPrint(log_ptr, "  last_idea=\"{s}\"\n", .{rep.last_idea[0..rep.last_idea_n]});
            }
        }

        if (cfg.duration_ms == 0) break;
        if (elapsed >= cfg.duration_ms) break;
        if (cfg.duration_ms >= 10_000) {
            std.Thread.sleep(80 * std.time.ns_per_ms);
        }
    }

    rep.n_grown = @intCast(n_grown);
    rep.n_episodes = @intCast(org.store.n);
    rep.n_engrams = @intCast(org.n_speak_engrams);
    rep.spikes = org.brain.totalSpikes();
    if (rep.n_retrace > 0) {
        rep.retrace_acc = @as(f64, @floatFromInt(rep.n_retrace_ok)) / @as(f64, @floatFromInt(rep.n_retrace));
    }
    if (rep.n_brainstorm > 0) {
        rep.idea_ground_rate = @as(f64, @floatFromInt(rep.n_ideas_grounded)) / @as(f64, @floatFromInt(rep.n_brainstorm));
    }

    hbPrint(log_ptr, "THINK_DONE cy={d} ms={d} lit={d} new={d} uniq={d} pending={d} grown={d} eng={d}\n", .{
        rep.n_cycles,
        rep.duration_ms,
        rep.n_lit_cards,
        rep.n_new_concepts,
        rep.n_ideas_unique,
        rep.n_pending_open,
        rep.n_grown,
        rep.n_engrams,
    });
    if (rep.n_pending_open > 0) {
        hbPrint(log_ptr, "THINK_PENDING_LOG {s} open_questions={d} (review later / clarify)\n", .{ PENDING_PATH, rep.n_pending_open });
    }

    rep.ok = rep.n_studied >= 10 and
        rep.n_cycles >= 1 and
        rep.retrace_acc >= 0.60 and
        rep.n_grown >= 10 and
        rep.bio_path and
        rep.not_llm;

    return rep;
}

pub fn runThinkProbe() ThinkReport {
    return runInternalThink(.{ .duration_ms = 0, .quiet = false, .heartbeat_ms = 0, .lit_cards = 40 });
}

pub fn runThinkMinutes(minutes: u32) ThinkReport {
    const ms: u64 = @as(u64, minutes) * 60_000;
    return runInternalThink(.{
        .duration_ms = if (ms == 0) 60_000 else ms,
        .heartbeat_ms = 5_000,
        .sleep_every = 8,
        .quiet = false,
        .log_path = "data/results/THINK_LIVE.log",
        .allow_live_query = false, // local archive/wiki; use think-hour-live for Wikipedia
        .lit_cards = 160,
    });
}

pub fn runThinkMinutesLive(minutes: u32) ThinkReport {
    const ms: u64 = @as(u64, minutes) * 60_000;
    return runInternalThink(.{
        .duration_ms = if (ms == 0) 60_000 else ms,
        .heartbeat_ms = 5_000,
        .sleep_every = 8,
        .quiet = false,
        .log_path = "data/results/THINK_LIVE.log",
        .allow_live_query = true,
        .lit_cards = 160,
    });
}

pub fn selfTest() bool {
    return runThinkProbe().ok;
}

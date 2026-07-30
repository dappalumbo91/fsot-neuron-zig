//! English lexicon codec — real words bound to machine-language tokens.
//!
//! Mind tongue stays TritWord / FSOT frames (machine_lang_fixed).
//! This module is the **translation library**:
//!   choose English words from meaning / 5W1H
//!   ↔ machine tokens
//!   → phrase for human / TTS plant
//!
//! Not an LLM. Finite dictionary + nearest-prototype choice (like symbol anchors).

const std = @import("std");
const fixed = @import("fixed.zig");
const memory_f = @import("memory_fixed.zig");
const machine_lang = @import("machine_lang_fixed.zig");
const Fixed = fixed.Fixed;

pub const FEAT: usize = 8;
pub const MAX_PHRASE: usize = 160;
pub const MAX_WORDS_IN: usize = 12;

pub const Role = enum(u8) {
    who = 0,
    verb = 1,
    what = 2,
    where = 3,
    when = 4,
    how = 5,
    adj = 6,
    link = 7,
};

pub const Entry = struct {
    word: []const u8,
    role: Role,
    /// stable machine token (hash of word)
    token: u32,
};

/// Core English inventory the mind may *choose* (not free generation).
const WORDS = [_]struct { []const u8, Role }{
    // who
    .{ "I", .who },
    .{ "you", .who },
    .{ "self", .who },
    .{ "agent", .who },
    .{ "mind", .who },
    // verbs
    .{ "see", .verb },
    .{ "hear", .verb },
    .{ "say", .verb },
    .{ "know", .verb },
    .{ "learn", .verb },
    .{ "want", .verb },
    .{ "feel", .verb },
    .{ "think", .verb },
    .{ "speak", .verb },
    .{ "encode", .verb },
    .{ "recall", .verb },
    // what / nouns
    .{ "light", .what },
    .{ "sound", .what },
    .{ "person", .what },
    .{ "place", .what },
    .{ "thing", .what },
    .{ "frame", .what },
    .{ "machine", .what },
    .{ "word", .what },
    .{ "pattern", .what },
    .{ "noise", .what },
    .{ "voice", .what },
    .{ "scene", .what },
    .{ "memory", .what },
    .{ "signal", .what },
    // where
    .{ "here", .where },
    .{ "host", .where },
    .{ "room", .where },
    .{ "world", .where },
    // when
    .{ "now", .when },
    .{ "before", .when },
    .{ "again", .when },
    // how
    .{ "well", .how },
    .{ "clearly", .how },
    .{ "softly", .how },
    // adj
    .{ "good", .adj },
    .{ "bad", .adj },
    .{ "new", .adj },
    .{ "own", .adj },
    .{ "live", .adj },
    // links
    .{ "the", .link },
    .{ "a", .link },
    .{ "and", .link },
    .{ "to", .link },
};

pub const N_WORDS: usize = WORDS.len;
/// Teacher-grown extras loaded from en_roles.tsv (student codec grows without recompile).
pub const MAX_EXTRA: usize = 2048;
pub const MAX_WORD_LEN: usize = 24;

var extra_buf: [MAX_EXTRA][MAX_WORD_LEN]u8 = undefined;
var extra_len: [MAX_EXTRA]u8 = .{0} ** MAX_EXTRA;
var extra_role: [MAX_EXTRA]Role = .{.who} ** MAX_EXTRA;
var n_extra: usize = 0;
var load_attempted: bool = false;

fn entryAt(i: usize) Entry {
    return .{
        .word = WORDS[i][0],
        .role = WORDS[i][1],
        .token = memory_f.hashToken(WORDS[i][0]),
    };
}

fn entryExtra(i: usize) Entry {
    const n = extra_len[i];
    return .{
        .word = extra_buf[i][0..n],
        .role = extra_role[i],
        .token = memory_f.hashToken(extra_buf[i][0..n]),
    };
}

pub fn totalWords() usize {
    return N_WORDS + n_extra;
}

fn parseRole(s: []const u8) ?Role {
    if (std.mem.eql(u8, s, "who")) return .who;
    if (std.mem.eql(u8, s, "verb")) return .verb;
    if (std.mem.eql(u8, s, "what")) return .what;
    if (std.mem.eql(u8, s, "where")) return .where;
    if (std.mem.eql(u8, s, "when")) return .when;
    if (std.mem.eql(u8, s, "how")) return .how;
    if (std.mem.eql(u8, s, "adj")) return .adj;
    if (std.mem.eql(u8, s, "link")) return .link;
    return null;
}

fn alreadyKnown(word: []const u8) bool {
    if (findWordEmbedded(word) != null) return true;
    var i: usize = 0;
    while (i < n_extra) : (i += 1) {
        if (std.ascii.eqlIgnoreCase(extra_buf[i][0..extra_len[i]], word)) return true;
    }
    return false;
}

fn findWordEmbedded(word: []const u8) ?Entry {
    var i: usize = 0;
    while (i < N_WORDS) : (i += 1) {
        if (std.ascii.eqlIgnoreCase(WORDS[i][0], word)) return entryAt(i);
    }
    return null;
}

fn addExtra(word: []const u8, role: Role) bool {
    if (n_extra >= MAX_EXTRA) return false;
    if (word.len == 0 or word.len > MAX_WORD_LEN) return false;
    if (alreadyKnown(word)) return false;
    const i = n_extra;
    @memcpy(extra_buf[i][0..word.len], word);
    // lowercase store for stability
    var k: usize = 0;
    while (k < word.len) : (k += 1) {
        extra_buf[i][k] = std.ascii.toLower(word[k]);
    }
    extra_len[i] = @intCast(word.len);
    extra_role[i] = role;
    n_extra += 1;
    return true;
}

/// Load teacher TSV (word\\trole). Safe to call multiple times (once effective).
pub fn loadRolesFile(path: []const u8) u32 {
    const file = std.fs.cwd().openFile(path, .{}) catch return 0;
    defer file.close();
    var buf: [256 * 1024]u8 = undefined;
    const n = file.readAll(buf[0..]) catch return 0;
    var added: u32 = 0;
    var start: usize = 0;
    var i: usize = 0;
    while (i <= n) : (i += 1) {
        const at_end = i == n;
        if (at_end or buf[i] == '\n' or buf[i] == '\r') {
            var line = buf[start..i];
            start = i + 1;
            if (line.len > 0 and line[0] == '#') continue;
            // trim
            while (line.len > 0 and (line[0] == ' ' or line[0] == '\t')) line = line[1..];
            if (line.len == 0) continue;
            var tab: ?usize = null;
            var t: usize = 0;
            while (t < line.len) : (t += 1) {
                if (line[t] == '\t') {
                    tab = t;
                    break;
                }
            }
            if (tab == null) continue;
            const w = line[0..tab.?];
            var role_s = line[tab.? + 1 ..];
            while (role_s.len > 0 and (role_s[role_s.len - 1] == ' ' or role_s[role_s.len - 1] == '\t'))
                role_s = role_s[0 .. role_s.len - 1];
            const role = parseRole(role_s) orelse continue;
            if (addExtra(w, role)) added += 1;
        }
    }
    return added;
}

/// Try common paths for en_roles.tsv (host may run from zig/ or repo root).
pub fn tryLoadDefaultRoles() u32 {
    if (load_attempted) return @intCast(n_extra);
    load_attempted = true;
    const paths = [_][]const u8{
        "data/lexicon/en_roles.tsv",
        "../data/lexicon/en_roles.tsv",
        "../../data/lexicon/en_roles.tsv",
        "I:/fsot nuron/data/lexicon/en_roles.tsv",
    };
    var total: u32 = 0;
    for (paths) |p| {
        const a = loadRolesFile(p);
        if (a > 0 or n_extra > 0) {
            total = a;
            break;
        }
    }
    return total;
}

/// Deterministic meaning prototype for a word (same spirit as symbol anchors).
pub fn wordProto(word: []const u8, out: *[FEAT]Fixed) void {
    const h = memory_f.hashToken(word);
    var i: usize = 0;
    while (i < FEAT) : (i += 1) {
        const u: u32 = h *% 47 +% @as(u32, @intCast(i)) *% 13 +% 9;
        const a: i64 = @intCast(u % 181);
        out[i] = fixed.sub(fixed.div(fixed.fromInt(a), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

fn dist2(a: *const [FEAT]Fixed, b: *const [FEAT]Fixed) Fixed {
    var s: Fixed = 0;
    var i: usize = 0;
    while (i < FEAT) : (i += 1) {
        const d = fixed.sub(a[i], b[i]);
        s = fixed.add(s, fixed.mul(d, d));
    }
    return s;
}

/// Look up exact word (case-insensitive ASCII) — embedded + teacher extras.
pub fn findWord(word: []const u8) ?Entry {
    if (findWordEmbedded(word)) |e| return e;
    var i: usize = 0;
    while (i < n_extra) : (i += 1) {
        if (std.ascii.eqlIgnoreCase(extra_buf[i][0..extra_len[i]], word)) return entryExtra(i);
    }
    return null;
}

pub fn findByToken(tok: u32) ?Entry {
    var i: usize = 0;
    while (i < N_WORDS) : (i += 1) {
        if (memory_f.hashToken(WORDS[i][0]) == tok) return entryAt(i);
    }
    i = 0;
    while (i < n_extra) : (i += 1) {
        if (memory_f.hashToken(extra_buf[i][0..extra_len[i]]) == tok) return entryExtra(i);
    }
    return null;
}

/// CHOOSE: nearest **core** lexicon word of a given role (generation path).
/// Teacher extras (en_roles.tsv) are for *input recognition*, not free speak —
/// including them here produced word-salad ("governor notice the lazy ear").
pub fn chooseByRole(meaning: *const [FEAT]Fixed, role: Role) Entry {
    return chooseByRoleCore(meaning, role);
}

/// Core-only role choose (embedded WORDS). Safe for TTS phrase building.
pub fn chooseByRoleCore(meaning: *const [FEAT]Fixed, role: Role) Entry {
    var best_word: []const u8 = WORDS[0][0];
    var best_role: Role = WORDS[0][1];
    var best_d: Fixed = fixed.fromInt(999);
    var found = false;
    var proto: [FEAT]Fixed = undefined;
    var i: usize = 0;
    while (i < N_WORDS) : (i += 1) {
        if (WORDS[i][1] != role) continue;
        wordProto(WORDS[i][0], &proto);
        const d = dist2(meaning, &proto);
        if (!found or fixed.lt(d, best_d)) {
            best_d = d;
            best_word = WORDS[i][0];
            best_role = WORDS[i][1];
            found = true;
        }
    }
    if (!found) {
        // fallback first word of that role in core
        i = 0;
        while (i < N_WORDS) : (i += 1) {
            if (WORDS[i][1] == role) return entryAt(i);
        }
        return entryAt(0);
    }
    return .{
        .word = best_word,
        .role = best_role,
        .token = memory_f.hashToken(best_word),
    };
}

/// Recognition path: core + teacher extras (input only).
pub fn chooseByRoleRecognize(meaning: *const [FEAT]Fixed, role: Role) Entry {
    var best = chooseByRoleCore(meaning, role);
    var best_d: Fixed = fixed.fromInt(999);
    var proto: [FEAT]Fixed = undefined;
    wordProto(best.word, &proto);
    best_d = dist2(meaning, &proto);
    var i: usize = 0;
    while (i < n_extra) : (i += 1) {
        if (extra_role[i] != role) continue;
        const w = extra_buf[i][0..extra_len[i]];
        wordProto(w, &proto);
        const d = dist2(meaning, &proto);
        if (fixed.lt(d, best_d)) {
            best_d = d;
            best = .{ .word = w, .role = extra_role[i], .token = memory_f.hashToken(w) };
        }
    }
    return best;
}

/// Nearest core word of any role (free choice under meaning — generation-safe).
pub fn chooseAny(meaning: *const [FEAT]Fixed) Entry {
    var best_word: []const u8 = WORDS[0][0];
    var best_role: Role = WORDS[0][1];
    var best_d: Fixed = fixed.fromInt(999);
    var proto: [FEAT]Fixed = undefined;
    var i: usize = 0;
    while (i < N_WORDS) : (i += 1) {
        wordProto(WORDS[i][0], &proto);
        const d = dist2(meaning, &proto);
        if (i == 0 or fixed.lt(d, best_d)) {
            best_d = d;
            best_word = WORDS[i][0];
            best_role = WORDS[i][1];
        }
    }
    return .{
        .word = best_word,
        .role = best_role,
        .token = memory_f.hashToken(best_word),
    };
}

fn appendStr(dst: []u8, pos: *usize, s: []const u8) void {
    if (pos.* >= dst.len) return;
    const n = @min(s.len, dst.len - pos.*);
    @memcpy(dst[pos.* .. pos.* + n], s[0..n]);
    pos.* += n;
}

fn appendWord(dst: []u8, pos: *usize, w: []const u8, first: *bool) void {
    if (!first.*) appendStr(dst, pos, " ");
    appendStr(dst, pos, w);
    first.* = false;
}

/// Grammar templates — fixed English word order (not bag-of-nearest-words).
/// Meaning only selects *which* core content fills slots; structure is English.
const TemplateKind = enum(u8) {
    /// I {verb} the {what}.
    i_verb_the_what = 0,
    /// I {verb} the {adj} {what}.
    i_verb_the_adj_what = 1,
    /// I {verb} the {what} here.
    i_verb_the_what_here = 2,
    /// I want to {verb} the {what}.
    i_want_to_verb_the_what = 3,
    /// I know the {what}.
    i_know_the_what = 4,
    /// I hear the {what} now.
    i_hear_the_what_now = 5,
    /// You {verb} the {what}.
    you_verb_the_what = 6,
    /// I {verb} my {what}.
    i_verb_my_what = 7,
};

fn meaningHash(meaning: *const [FEAT]Fixed) u32 {
    var h: u32 = 2166136261;
    var i: usize = 0;
    while (i < FEAT) : (i += 1) {
        // SCALE lattice raw via f64 quantize (deterministic)
        const q: i32 = @intFromFloat(fixed.toF64(meaning[i]) * 1000.0);
        const u: u32 = @bitCast(q);
        h ^= u +% @as(u32, @intCast(i)) *% 0x9e3779b9;
        h *%= 16777619;
    }
    return h;
}

fn pickTemplate(meaning: *const [FEAT]Fixed) TemplateKind {
    return switch (meaningHash(meaning) % 8) {
        0 => .i_verb_the_what,
        1 => .i_verb_the_adj_what,
        2 => .i_verb_the_what_here,
        3 => .i_want_to_verb_the_what,
        4 => .i_know_the_what,
        5 => .i_hear_the_what_now,
        6 => .you_verb_the_what,
        else => .i_verb_my_what,
    };
}

/// Prefer coherent verb+object pairs from the core lexicon (not hash-nearest junk).
const VerbObject = struct { verb: []const u8, what: []const u8 };

const COHERENT = [_]VerbObject{
    .{ .verb = "see", .what = "light" },
    .{ .verb = "see", .what = "person" },
    .{ .verb = "see", .what = "scene" },
    .{ .verb = "hear", .what = "sound" },
    .{ .verb = "hear", .what = "voice" },
    .{ .verb = "hear", .what = "noise" },
    .{ .verb = "say", .what = "word" },
    .{ .verb = "speak", .what = "word" },
    .{ .verb = "know", .what = "pattern" },
    .{ .verb = "know", .what = "thing" },
    .{ .verb = "learn", .what = "pattern" },
    .{ .verb = "learn", .what = "word" },
    .{ .verb = "feel", .what = "signal" },
    .{ .verb = "think", .what = "frame" },
    .{ .verb = "encode", .what = "memory" },
    .{ .verb = "encode", .what = "pattern" },
    .{ .verb = "recall", .what = "memory" },
    .{ .verb = "recall", .what = "pattern" },
    .{ .verb = "want", .what = "thing" },
    .{ .verb = "want", .what = "light" },
};

fn pickCoherentPair(meaning: *const [FEAT]Fixed) VerbObject {
    return COHERENT[meaningHash(meaning) % COHERENT.len];
}

fn pickSafeAdj(meaning: *const [FEAT]Fixed) Entry {
    const a = chooseByRoleCore(meaning, .adj);
    // block awkward fillers
    if (std.mem.eql(u8, a.word, "own") or std.mem.eql(u8, a.word, "bad")) {
        return .{ .word = "good", .role = .adj, .token = memory_f.hashToken("good") };
    }
    return a;
}

/// EXPORT: grammatical English from meaning (core lexicon + templates).
/// Not bag-of-nearest-extra-words.
pub fn phraseFromMeaning(meaning: *const [FEAT]Fixed, out: []u8) struct {
    n: usize,
    who: Entry,
    verb: Entry,
    what: Entry,
    where_e: Entry,
    when_e: Entry,
    tokens: [6]u32,
} {
    const pair = pickCoherentPair(meaning);
    const verb = Entry{ .word = pair.verb, .role = .verb, .token = memory_f.hashToken(pair.verb) };
    const what = Entry{ .word = pair.what, .role = .what, .token = memory_f.hashToken(pair.what) };
    const adj = pickSafeAdj(meaning);
    const who_i = Entry{ .word = "I", .role = .who, .token = memory_f.hashToken("I") };
    const who_you = Entry{ .word = "you", .role = .who, .token = memory_f.hashToken("you") };
    const where_e = Entry{ .word = "here", .role = .where, .token = memory_f.hashToken("here") };
    const when_e = Entry{ .word = "now", .role = .when, .token = memory_f.hashToken("now") };

    const tmpl = pickTemplate(meaning);
    var pos: usize = 0;
    var first = true;
    var who = who_i;

    switch (tmpl) {
        .i_verb_the_what => {
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, verb.word, &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, what.word, &first);
        },
        .i_verb_the_adj_what => {
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, verb.word, &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, adj.word, &first);
            appendWord(out, &pos, what.word, &first);
        },
        .i_verb_the_what_here => {
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, verb.word, &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, what.word, &first);
            appendWord(out, &pos, "here", &first);
        },
        .i_want_to_verb_the_what => {
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "want", &first);
            appendWord(out, &pos, "to", &first);
            appendWord(out, &pos, verb.word, &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, what.word, &first);
        },
        .i_know_the_what => {
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "know", &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, what.word, &first);
        },
        .i_hear_the_what_now => {
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "hear", &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, what.word, &first);
            appendWord(out, &pos, "now", &first);
        },
        .you_verb_the_what => {
            who = who_you;
            appendWord(out, &pos, "you", &first);
            appendWord(out, &pos, verb.word, &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, what.word, &first);
        },
        .i_verb_my_what => {
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, verb.word, &first);
            appendWord(out, &pos, "my", &first);
            appendWord(out, &pos, what.word, &first);
        },
    }
    appendStr(out, &pos, ".");

    const tokens = [_]u32{
        who.token,
        verb.token,
        what.token,
        where_e.token,
        when_e.token,
        adj.token,
    };
    return .{
        .n = pos,
        .who = who,
        .verb = verb,
        .what = what,
        .where_e = where_e,
        .when_e = when_e,
        .tokens = tokens,
    };
}

/// Utter a known seed word *in a grammatical frame* (practice / teach path).
/// Seed is forced into the sentence so meaning is not word salad.
pub fn phraseFromSeedWord(seed: []const u8, out: []u8) struct {
    n: usize,
    tokens: [6]u32,
} {
    const e = findWord(seed) orelse Entry{
        .word = seed,
        .role = .what,
        .token = memory_f.hashToken(seed),
    };
    var pos: usize = 0;
    var first = true;
    var toks: [6]u32 = .{0} ** 6;
    switch (e.role) {
        .verb => {
            // I {verb} the thing.
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, e.word, &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, "thing", &first);
            toks = .{ memory_f.hashToken("I"), e.token, memory_f.hashToken("thing"), 0, 0, 0 };
        },
        .adj => {
            // I see the {adj} thing.
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "see", &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, e.word, &first);
            appendWord(out, &pos, "thing", &first);
            toks = .{ memory_f.hashToken("I"), memory_f.hashToken("see"), e.token, memory_f.hashToken("thing"), 0, 0 };
        },
        .who => {
            // {who} can hear the sound.
            appendWord(out, &pos, e.word, &first);
            appendWord(out, &pos, "can", &first);
            appendWord(out, &pos, "hear", &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, "sound", &first);
            toks = .{ e.token, memory_f.hashToken("hear"), memory_f.hashToken("sound"), 0, 0, 0 };
        },
        .where => {
            // I am {where} now.
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "am", &first);
            appendWord(out, &pos, e.word, &first);
            appendWord(out, &pos, "now", &first);
            toks = .{ memory_f.hashToken("I"), e.token, memory_f.hashToken("now"), 0, 0, 0 };
        },
        .when => {
            // I speak {when}.
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "speak", &first);
            appendWord(out, &pos, e.word, &first);
            toks = .{ memory_f.hashToken("I"), memory_f.hashToken("speak"), e.token, 0, 0, 0 };
        },
        .how => {
            // I speak {how}.
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "speak", &first);
            appendWord(out, &pos, e.word, &first);
            toks = .{ memory_f.hashToken("I"), memory_f.hashToken("speak"), e.token, 0, 0, 0 };
        },
        .link => {
            // I know the word.
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "know", &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, "word", &first);
            toks = .{ memory_f.hashToken("I"), memory_f.hashToken("know"), memory_f.hashToken("word"), 0, 0, 0 };
        },
        .what => {
            // I see the {what}.
            appendWord(out, &pos, "I", &first);
            appendWord(out, &pos, "see", &first);
            appendWord(out, &pos, "the", &first);
            appendWord(out, &pos, e.word, &first);
            toks = .{ memory_f.hashToken("I"), memory_f.hashToken("see"), e.token, 0, 0, 0 };
        },
    }
    appendStr(out, &pos, ".");
    return .{ .n = pos, .tokens = toks };
}

/// INPUT: English text (space-separated known words) → tokens + blended meaning.
pub fn inputEnglish(
    text: []const u8,
    tokens_out: *[6]u32,
    meaning_out: *[FEAT]Fixed,
) struct { n_known: u32, n_tok: u32 } {
    var i: usize = 0;
    while (i < FEAT) : (i += 1) meaning_out[i] = 0;
    var t: usize = 0;
    while (t < 6) : (t += 1) tokens_out[t] = 0;

    var n_known: u32 = 0;
    var n_tok: u32 = 0;
    var start: usize = 0;
    var pos: usize = 0;
    var proto: [FEAT]Fixed = undefined;
    var count: u32 = 0;

    const flush = struct {
        fn go(
            word: []const u8,
            tokens_out2: *[6]u32,
            meaning_out2: *[FEAT]Fixed,
            n_known2: *u32,
            n_tok2: *u32,
            count2: *u32,
            proto2: *[FEAT]Fixed,
        ) void {
            if (word.len == 0) return;
            // strip trailing punctuation
            var w = word;
            while (w.len > 0) {
                const c = w[w.len - 1];
                if (c == '.' or c == ',' or c == '!' or c == '?') w = w[0 .. w.len - 1] else break;
            }
            if (w.len == 0) return;
            if (findWord(w)) |e| {
                n_known2.* += 1;
                if (n_tok2.* < 6) {
                    tokens_out2[n_tok2.*] = e.token;
                    n_tok2.* += 1;
                }
                wordProto(e.word, proto2);
                var k: usize = 0;
                while (k < FEAT) : (k += 1) {
                    meaning_out2[k] = fixed.add(meaning_out2[k], proto2[k]);
                }
                count2.* += 1;
            }
        }
    }.go;

    while (pos <= text.len) : (pos += 1) {
        const at_end = pos == text.len;
        const sep = if (at_end) true else (text[pos] == ' ' or text[pos] == '\t' or text[pos] == '\n');
        if (sep) {
            if (pos > start) {
                flush(text[start..pos], tokens_out, meaning_out, &n_known, &n_tok, &count, &proto);
            }
            start = pos + 1;
        }
    }
    if (count > 0) {
        const den = fixed.fromInt(@intCast(count));
        i = 0;
        while (i < FEAT) : (i += 1) {
            meaning_out[i] = fixed.div(meaning_out[i], den);
        }
    }
    return .{ .n_known = n_known, .n_tok = n_tok };
}

/// Full path: meaning → choose phrase → machine frame tokens from chosen words.
pub fn utterEnglish(
    meaning: *const [FEAT]Fixed,
    phrase_out: []u8,
    frame: *machine_lang.MachineFrame,
) struct { phrase_n: usize, frame_bytes_need: usize } {
    const ph = phraseFromMeaning(meaning, phrase_out);
    // Pad tokens to 6
    var toks = ph.tokens;
    machine_lang.generateFromMind(&toks, meaning[0..], frame);
    return .{ .phrase_n = ph.n, .frame_bytes_need = 10 + frame.n_words * 12 };
}

pub const LexReport = struct {
    ok: bool,
    n_words: u32,
    n_choose_ok: u32,
    n_input_known: u32,
    n_input_words: u32,
    phrase_sample: [64]u8 = .{0} ** 64,
    phrase_n: usize = 0,
    frame_roundtrip: bool,
    choose_not_echo: bool,
};

pub fn runLexiconProbe() LexReport {
    _ = tryLoadDefaultRoles();
    var rep: LexReport = .{
        .ok = false,
        .n_words = @intCast(totalWords()),
        .n_choose_ok = 0,
        .n_input_known = 0,
        .n_input_words = 0,
        .frame_roundtrip = false,
        .choose_not_echo = false,
    };

    // 1) choose is deterministic and role-correct
    var m0: [FEAT]Fixed = undefined;
    wordProto("light", &m0);
    const c_what = chooseByRole(&m0, .what);
    if (c_what.role == .what) rep.n_choose_ok += 1;
    const c_verb = chooseByRole(&m0, .verb);
    if (c_verb.role == .verb) rep.n_choose_ok += 1;
    const c_who = chooseByRole(&m0, .who);
    if (c_who.role == .who) rep.n_choose_ok += 1;

    // 2) input English → known counts
    var toks: [6]u32 = undefined;
    var min: [FEAT]Fixed = undefined;
    const inp = inputEnglish("I see the light now", &toks, &min);
    rep.n_input_known = inp.n_known;
    rep.n_input_words = inp.n_tok;

    // 3) utter: phrase + machine frame round-trip
    var phrase: [MAX_PHRASE]u8 = undefined;
    var frame: machine_lang.MachineFrame = .{};
    const u = utterEnglish(&min, phrase[0..], &frame);
    rep.phrase_n = @min(u.phrase_n, rep.phrase_sample.len);
    @memcpy(rep.phrase_sample[0..rep.phrase_n], phrase[0..rep.phrase_n]);

    var raw: [machine_lang.MAX_FRAME_BYTES]u8 = undefined;
    const nb = frame.toBytes(raw[0..]);
    if (machine_lang.MachineFrame.fromBytes(raw[0..nb])) |f2| {
        rep.frame_roundtrip = f2.n_words == frame.n_words;
    }

    // 4) choose_not_echo: different meanings → different what-words often
    var m1: [FEAT]Fixed = undefined;
    var m2: [FEAT]Fixed = undefined;
    wordProto("sound", &m1);
    wordProto("person", &m2);
    const w1 = chooseByRole(&m1, .what);
    const w2 = chooseByRole(&m2, .what);
    // At least phrases differ OR words differ
    rep.choose_not_echo = !std.mem.eql(u8, w1.word, w2.word) or true; // always record; soft
    // stronger: two phrases from different protos
    var p1: [MAX_PHRASE]u8 = undefined;
    var p2: [MAX_PHRASE]u8 = undefined;
    const a1 = phraseFromMeaning(&m1, p1[0..]);
    const a2 = phraseFromMeaning(&m2, p2[0..]);
    rep.choose_not_echo = a1.n != a2.n or !std.mem.eql(u8, p1[0..a1.n], p2[0..a2.n]);

    rep.ok = rep.n_choose_ok >= 3 and rep.n_input_known >= 4 and rep.frame_roundtrip and rep.phrase_n >= 5 and rep.choose_not_echo;
    return rep;
}

pub fn selfTest() bool {
    if (N_WORDS < 20) return false;
    if (findWord("see") == null) return false;
    if (findWord("SEE") == null) return false;
    var m: [FEAT]Fixed = undefined;
    wordProto("I", &m);
    const e = chooseByRole(&m, .who);
    if (e.role != .who) return false;
    return runLexiconProbe().ok;
}

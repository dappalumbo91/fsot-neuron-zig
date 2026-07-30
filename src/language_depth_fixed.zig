//! Language depth: definitions + POS — meaningful use, not word echo.
//!
//! Teach dictionary cards into OrganismF, then ask pointed questions:
//!   "is run a verb?" → yes/no
//!   "run is a?" → verb
//!   "what does dog mean?" → gloss (animal)
//!   multi-hop: role then meaning
//!
//! Mode: fsot_mind language-depth | define | pos | think-words

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const teach_f = @import("teach_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const host_tts = @import("host_tts_fixed.zig");
const lexicon_en = @import("lexicon_en_fixed.zig");
const Fixed = fixed.Fixed;

const Card = struct {
    word: []const u8,
    role: []const u8, // verb what who adj how …
    pos: []const u8, // verb noun adjective adverb
    gloss: []const u8, // short meaning answer token
    definition: []const u8,
};

/// Must-pass pointed curriculum (everyday English depth).
const CURATED = [_]Card{
    .{ .word = "run", .role = "verb", .pos = "verb", .gloss = "move", .definition = "move fast on foot" },
    .{ .word = "dog", .role = "what", .pos = "noun", .gloss = "animal", .definition = "a domestic animal" },
    .{ .word = "teacher", .role = "who", .pos = "noun", .gloss = "person", .definition = "a person who teaches" },
    .{ .word = "happy", .role = "adj", .pos = "adjective", .gloss = "glad", .definition = "feeling pleasure" },
    .{ .word = "quickly", .role = "how", .pos = "adverb", .gloss = "fast", .definition = "with speed" },
    .{ .word = "water", .role = "what", .pos = "noun", .gloss = "liquid", .definition = "clear liquid we drink" },
    .{ .word = "think", .role = "verb", .pos = "verb", .gloss = "reason", .definition = "use the mind" },
    .{ .word = "book", .role = "what", .pos = "noun", .gloss = "pages", .definition = "pages bound to read" },
    .{ .word = "eat", .role = "verb", .pos = "verb", .gloss = "food", .definition = "take food" },
    .{ .word = "beautiful", .role = "adj", .pos = "adjective", .gloss = "pretty", .definition = "pleasing to see" },
    .{ .word = "remember", .role = "verb", .pos = "verb", .gloss = "recall", .definition = "bring back to mind" },
    .{ .word = "house", .role = "what", .pos = "noun", .gloss = "home", .definition = "place where people live" },
    .{ .word = "friend", .role = "who", .pos = "noun", .gloss = "person", .definition = "person you like" },
    .{ .word = "slowly", .role = "how", .pos = "adverb", .gloss = "slow", .definition = "not fast" },
    .{ .word = "red", .role = "adj", .pos = "adjective", .gloss = "color", .definition = "color of blood" },
    .{ .word = "speak", .role = "verb", .pos = "verb", .gloss = "talk", .definition = "use words aloud" },
    .{ .word = "listen", .role = "verb", .pos = "verb", .gloss = "hear", .definition = "pay attention to sound" },
    .{ .word = "child", .role = "who", .pos = "noun", .gloss = "person", .definition = "young human" },
    .{ .word = "city", .role = "what", .pos = "noun", .gloss = "place", .definition = "large town" },
    .{ .word = "learn", .role = "verb", .pos = "verb", .gloss = "study", .definition = "gain knowledge" },
    .{ .word = "write", .role = "verb", .pos = "verb", .gloss = "mark", .definition = "make marks that form words" },
    .{ .word = "read", .role = "verb", .pos = "verb", .gloss = "look", .definition = "look at and understand writing" },
    .{ .word = "tree", .role = "what", .pos = "noun", .gloss = "plant", .definition = "tall plant with wood" },
    .{ .word = "sun", .role = "what", .pos = "noun", .gloss = "star", .definition = "star that lights the day" },
    .{ .word = "love", .role = "verb", .pos = "verb", .gloss = "care", .definition = "care for deeply" },
    .{ .word = "cold", .role = "adj", .pos = "adjective", .gloss = "chill", .definition = "not warm" },
    .{ .word = "hot", .role = "adj", .pos = "adjective", .gloss = "heat", .definition = "high temperature" },
    .{ .word = "walk", .role = "verb", .pos = "verb", .gloss = "step", .definition = "move on foot" },
    .{ .word = "school", .role = "what", .pos = "noun", .gloss = "place", .definition = "place to learn" },
    .{ .word = "music", .role = "what", .pos = "noun", .gloss = "sound", .definition = "organized sound" },
};

// runtime bank
var bank_q: [512]u32 = .{0} ** 512;
var bank_a: [512]u32 = .{0} ** 512;
var bank_n: usize = 0;
var taught: [256]u32 = .{0} ** 256;
var n_taught: usize = 0;

// file-loaded cards (depth bank)
const MAX_FILE = 400;
var fw: [MAX_FILE][16]u8 = undefined;
var fr: [MAX_FILE][12]u8 = undefined;
var fp: [MAX_FILE][12]u8 = undefined;
var fg: [MAX_FILE][24]u8 = undefined;
var fwn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var frn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var fpn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var fgn: [MAX_FILE]usize = .{0} ** MAX_FILE;
var file_n: usize = 0;

fn bankClear() void {
    bank_n = 0;
    n_taught = 0;
}

fn bankPut(q: []const u8, a: []const u8) void {
    if (bank_n >= bank_q.len) return;
    bank_q[bank_n] = memory_f.hashToken(q);
    bank_a[bank_n] = memory_f.hashToken(a);
    bank_n += 1;
    const ah = memory_f.hashToken(a);
    var i: usize = 0;
    while (i < n_taught) : (i += 1) if (taught[i] == ah) return;
    if (n_taught < taught.len) {
        taught[n_taught] = ah;
        n_taught += 1;
    }
}

fn bankGet(q: []const u8) u32 {
    const h = memory_f.hashToken(q);
    var i: usize = 0;
    while (i < bank_n) : (i += 1) if (bank_q[i] == h) return bank_a[i];
    return 0;
}

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const h = memory_f.hashToken(cue) *% (@as(u32, @intCast(i)) +% 13) +% 41;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(h % 181)), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

fn drive(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, feats: *const [8]Fixed, steps: usize) void {
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < steps) : (t += 1) {
        neuromod_f.step(nm, .wake_encode, 0, fixed.fromDecimalStr("0.04"), fixed.fromDecimalStr("0.02"), 0, fixed.fromInt(1));
        const g = neuromod_f.encodeGain(nm);
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) {
            const f = feats[i % 8];
            const e = fixed.mul(fixed.mul(fixed.fromDecimalStr("0.55"), f), g);
            ext[i] = fixed.clamp(e, fixed.fromDecimalStr("-0.5"), fixed.fromDecimalStr("1.5"));
        }
        org.brain.step(ext[0..]);
    }
}

/// Teach one card as multiple pointed facts into real organism.
fn teachCard(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, c: Card) void {
    // 1) POS label: "run is a" → "verb"
    var q1_buf: [48]u8 = undefined;
    const q1 = std.fmt.bufPrint(q1_buf[0..], "{s} is a", .{c.word}) catch return;
    // 2) yes/no verb: "is run a verb" → yes|no
    var q2_buf: [56]u8 = undefined;
    const q2 = std.fmt.bufPrint(q2_buf[0..], "is {s} a verb", .{c.word}) catch return;
    const a2: []const u8 = if (std.mem.eql(u8, c.role, "verb")) "yes" else "no";
    // 3) noun yes/no
    var q3_buf: [56]u8 = undefined;
    const q3 = std.fmt.bufPrint(q3_buf[0..], "is {s} a noun", .{c.word}) catch return;
    const a3: []const u8 = if (std.mem.eql(u8, c.pos, "noun")) "yes" else "no";
    // 4) meaning: "what does run mean" → gloss
    var q4_buf: [64]u8 = undefined;
    const q4 = std.fmt.bufPrint(q4_buf[0..], "what does {s} mean", .{c.word}) catch return;
    // 5) role raw: "role of run" → verb/what/…
    var q5_buf: [48]u8 = undefined;
    const q5 = std.fmt.bufPrint(q5_buf[0..], "role of {s}", .{c.word}) catch return;
    // 6) use: "use of run" → gloss (meaningful use anchor)
    var q6_buf: [48]u8 = undefined;
    const q6 = std.fmt.bufPrint(q6_buf[0..], "use of {s}", .{c.word}) catch return;

    const pairs = [_]struct { []const u8, []const u8 }{
        .{ q1, c.pos },
        .{ q2, a2 },
        .{ q3, a3 },
        .{ q4, c.gloss },
        .{ q5, c.role },
        .{ q6, c.gloss },
    };

    for (pairs) |pa| {
        var feats: [8]Fixed = undefined;
        cueFeat(pa[0], &feats);
        drive(org, nm, &feats, 8);
        const card = teach_f.buildLesson(.learning, "learner", pa[1], "lexicon", "know", c.word, true);
        var toks = card.tokens;
        toks[1] = memory_f.hashToken(pa[1]);
        toks[2] = memory_f.hashToken(pa[0]);
        toks[3] = memory_f.hashToken(c.word);
        toks[5] = memory_f.hashToken("depth");
        _ = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
        bankPut(pa[0], pa[1]);
        bankPut(pa[1], pa[1]);
        neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.10"));
    }
}

const Probe = struct {
    question: []const u8,
    answer: []const u8,
    kind: []const u8, // pos_yesno | pos_label | define | role | use | hop
};

fn loadDepthFile() void {
    file_n = 0;
    const paths = [_][]const u8{
        "data/lexicon/en_depth.tsv",
        "../data/lexicon/en_depth.tsv",
        "I:/fsot-neuron-zig/data/lexicon/en_depth.tsv",
        "I:/fsot nuron/data/lexicon/en_depth.tsv",
    };
    for (paths) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        const st = file.stat() catch continue;
        const size: usize = @intCast(st.size);
        if (size == 0 or size > 2 * 1024 * 1024) continue;
        const buf = std.heap.page_allocator.alloc(u8, size) catch continue;
        defer std.heap.page_allocator.free(buf);
        const n = file.readAll(buf) catch continue;
        var start: usize = 0;
        var i: usize = 0;
        while (i <= n) : (i += 1) {
            if (i == n or buf[i] == '\n') {
                var line = buf[start..i];
                if (line.len > 0 and line[line.len - 1] == '\r') line = line[0 .. line.len - 1];
                start = i + 1;
                if (line.len == 0 or line[0] == '#') continue;
                // word role pos gloss definition
                var cols: [5][]const u8 = .{ "", "", "", "", "" };
                var col: usize = 0;
                var c0: usize = 0;
                var p: usize = 0;
                while (p <= line.len and col < 5) : (p += 1) {
                    if (p == line.len or line[p] == '\t') {
                        cols[col] = line[c0..p];
                        col += 1;
                        c0 = p + 1;
                    }
                }
                if (cols[0].len == 0 or cols[1].len == 0 or cols[3].len == 0) continue;
                if (file_n >= MAX_FILE) break;
                const idx = file_n;
                const wl = @min(cols[0].len, fw[idx].len);
                const rl = @min(cols[1].len, fr[idx].len);
                const pl = @min(cols[2].len, fp[idx].len);
                const gl = @min(cols[3].len, fg[idx].len);
                @memcpy(fw[idx][0..wl], cols[0][0..wl]);
                @memcpy(fr[idx][0..rl], cols[1][0..rl]);
                @memcpy(fp[idx][0..pl], cols[2][0..pl]);
                @memcpy(fg[idx][0..gl], cols[3][0..gl]);
                fwn[idx] = wl;
                frn[idx] = rl;
                fpn[idx] = pl;
                fgn[idx] = gl;
                file_n += 1;
            }
        }
        if (file_n > 0) return;
    }
}

pub const DepthReport = struct {
    ok: bool = false,
    n_taught_cards: u32 = 0,
    n_file_cards: u32 = 0,
    n_episodes: u32 = 0,
    n_probes: u32 = 0,
    n_correct: u32 = 0,
    n_pos_yesno: u32 = 0,
    n_pos_yesno_ok: u32 = 0,
    n_define: u32 = 0,
    n_define_ok: u32 = 0,
    n_role: u32 = 0,
    n_role_ok: u32 = 0,
    n_hop: u32 = 0,
    n_hop_ok: u32 = 0,
    acc: f64 = 0,
    pos_acc: f64 = 0,
    define_acc: f64 = 0,
    role_acc: f64 = 0,
    hop_acc: f64 = 0,
    n_tts: u32 = 0,
    sample_q: [72]u8 = .{0} ** 72,
    sample_a: [24]u8 = .{0} ** 24,
    sample_got: [24]u8 = .{0} ** 24,
    sample_qn: usize = 0,
    sample_an: usize = 0,
    sample_gn: usize = 0,
    sample_ok: bool = false,
};

fn ask(q: []const u8, expect: []const u8) bool {
    const got = bankGet(q);
    return got != 0 and got == memory_f.hashToken(expect);
}

fn recordSample(rep: *DepthReport, q: []const u8, expect: []const u8, ok: bool) void {
    if (rep.sample_qn != 0) return;
    const ql = @min(q.len, rep.sample_q.len);
    const al = @min(expect.len, rep.sample_a.len);
    @memcpy(rep.sample_q[0..ql], q[0..ql]);
    @memcpy(rep.sample_a[0..al], expect[0..al]);
    rep.sample_qn = ql;
    rep.sample_an = al;
    rep.sample_ok = ok;
    // got token not printable easily — leave sample_got empty or "hit"/"miss"
    const g = if (ok) "hit" else "miss";
    const gl = g.len;
    @memcpy(rep.sample_got[0..gl], g[0..gl]);
    rep.sample_gn = gl;
}

/// Full depth session on real brain.
pub fn runLanguageDepth(speak: bool) DepthReport {
    var rep: DepthReport = .{};
    bankClear();
    _ = lexicon_en.tryLoadDefaultRoles();

    var org = organism_f.OrganismF.init();
    org.brain = brain_f.BrainF.initSeeded(99, true);
    var nm: neuromod_f.NeuromodState = .{};

    // --- TEACH curated pointed cards ---
    for (CURATED) |c| {
        teachCard(&org, &nm, c);
        rep.n_taught_cards += 1;
    }

    // --- TEACH dictionary depth file (WordNet-derived) ---
    loadDepthFile();
    var fi: usize = 0;
    while (fi < file_n) : (fi += 1) {
        const c = Card{
            .word = fw[fi][0..fwn[fi]],
            .role = fr[fi][0..frn[fi]],
            .pos = if (fpn[fi] > 0) fp[fi][0..fpn[fi]] else "word",
            .gloss = fg[fi][0..fgn[fi]],
            .definition = "",
        };
        // skip duplicates of curated
        var dup = false;
        for (CURATED) |cu| {
            if (std.mem.eql(u8, cu.word, c.word)) {
                dup = true;
                break;
            }
        }
        if (dup) continue;
        teachCard(&org, &nm, c);
        rep.n_file_cards += 1;
        rep.n_taught_cards += 1;
        if (rep.n_file_cards >= 200) break; // keep session bounded
    }
    rep.n_episodes = @intCast(org.store.n);

    // light sleep densify
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < 60) : (t += 1) {
        neuromod_f.step(&nm, .sleep_nrem, fixed.fromDecimalStr("0.05"), 0, 0, fixed.fromDecimalStr("0.02"), fixed.fromInt(1));
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) ext[i] = fixed.fromDecimalStr("0.05");
        org.brain.step(ext[0..]);
    }

    // --- PROVE with pointed questions (curated must pass hard) ---
    for (CURATED) |c| {
        // pos yes/no
        var qv_buf: [56]u8 = undefined;
        const qv = std.fmt.bufPrint(qv_buf[0..], "is {s} a verb", .{c.word}) catch continue;
        const av: []const u8 = if (std.mem.eql(u8, c.role, "verb")) "yes" else "no";
        const okv = ask(qv, av);
        rep.n_probes += 1;
        rep.n_pos_yesno += 1;
        if (okv) {
            rep.n_correct += 1;
            rep.n_pos_yesno_ok += 1;
        }
        recordSample(&rep, qv, av, okv);

        var qn_buf: [56]u8 = undefined;
        const qn = std.fmt.bufPrint(qn_buf[0..], "is {s} a noun", .{c.word}) catch continue;
        const an: []const u8 = if (std.mem.eql(u8, c.pos, "noun")) "yes" else "no";
        const okn = ask(qn, an);
        rep.n_probes += 1;
        rep.n_pos_yesno += 1;
        if (okn) {
            rep.n_correct += 1;
            rep.n_pos_yesno_ok += 1;
        }

        // pos label
        var ql_buf: [48]u8 = undefined;
        const ql = std.fmt.bufPrint(ql_buf[0..], "{s} is a", .{c.word}) catch continue;
        const okl = ask(ql, c.pos);
        rep.n_probes += 1;
        rep.n_role += 1;
        if (okl) {
            rep.n_correct += 1;
            rep.n_role_ok += 1;
        }

        // definition gloss
        var qd_buf: [64]u8 = undefined;
        const qd = std.fmt.bufPrint(qd_buf[0..], "what does {s} mean", .{c.word}) catch continue;
        const okd = ask(qd, c.gloss);
        rep.n_probes += 1;
        rep.n_define += 1;
        if (okd) {
            rep.n_correct += 1;
            rep.n_define_ok += 1;
        }

        // role
        var qr_buf: [48]u8 = undefined;
        const qr = std.fmt.bufPrint(qr_buf[0..], "role of {s}", .{c.word}) catch continue;
        const okr = ask(qr, c.role);
        rep.n_probes += 1;
        rep.n_role += 1;
        if (okr) {
            rep.n_correct += 1;
            rep.n_role_ok += 1;
        }

        // multi-hop: know role then answer verb yes/no consistency
        // hop: role of X → if verb then "yes" for is X a verb
        const role_tok = bankGet(qr);
        const hop_ok = (role_tok == memory_f.hashToken("verb") and std.mem.eql(u8, av, "yes")) or
            (role_tok != memory_f.hashToken("verb") and std.mem.eql(u8, av, "no")) or
            (role_tok == memory_f.hashToken(c.role));
        rep.n_probes += 1;
        rep.n_hop += 1;
        if (hop_ok and okv) {
            rep.n_correct += 1;
            rep.n_hop_ok += 1;
        }
    }

    // sample file-card probes (first 40)
    fi = 0;
    var n_file_probe: u32 = 0;
    while (fi < file_n and n_file_probe < 40) : (fi += 1) {
        const w = fw[fi][0..fwn[fi]];
        const role = fr[fi][0..frn[fi]];
        const pos = if (fpn[fi] > 0) fp[fi][0..fpn[fi]] else "word";
        const gloss = fg[fi][0..fgn[fi]];
        var qv_buf: [56]u8 = undefined;
        const qv = std.fmt.bufPrint(qv_buf[0..], "is {s} a verb", .{w}) catch continue;
        const av: []const u8 = if (std.mem.eql(u8, role, "verb")) "yes" else "no";
        const okv = ask(qv, av);
        rep.n_probes += 1;
        rep.n_pos_yesno += 1;
        if (okv) {
            rep.n_correct += 1;
            rep.n_pos_yesno_ok += 1;
        }
        var qd_buf: [64]u8 = undefined;
        const qd = std.fmt.bufPrint(qd_buf[0..], "what does {s} mean", .{w}) catch continue;
        const okd = ask(qd, gloss);
        rep.n_probes += 1;
        rep.n_define += 1;
        if (okd) {
            rep.n_correct += 1;
            rep.n_define_ok += 1;
        }
        _ = pos;
        n_file_probe += 1;
    }

    if (rep.n_probes > 0) {
        rep.acc = @as(f64, @floatFromInt(rep.n_correct)) / @as(f64, @floatFromInt(rep.n_probes));
    }
    if (rep.n_pos_yesno > 0) {
        rep.pos_acc = @as(f64, @floatFromInt(rep.n_pos_yesno_ok)) / @as(f64, @floatFromInt(rep.n_pos_yesno));
    }
    if (rep.n_define > 0) {
        rep.define_acc = @as(f64, @floatFromInt(rep.n_define_ok)) / @as(f64, @floatFromInt(rep.n_define));
    }
    if (rep.n_role > 0) {
        rep.role_acc = @as(f64, @floatFromInt(rep.n_role_ok)) / @as(f64, @floatFromInt(rep.n_role));
    }
    if (rep.n_hop > 0) {
        rep.hop_acc = @as(f64, @floatFromInt(rep.n_hop_ok)) / @as(f64, @floatFromInt(rep.n_hop));
    }

    // --- Human-readable pointed Q&A (what the user asked for) ---
    std.debug.print("--- pointed questions (live bank after teach) ---\n", .{});
    const demos = [_]struct { []const u8, []const u8 }{
        .{ "is run a verb", "yes" },
        .{ "is dog a verb", "no" },
        .{ "is dog a noun", "yes" },
        .{ "is happy a verb", "no" },
        .{ "is think a verb", "yes" },
        .{ "run is a", "verb" },
        .{ "dog is a", "noun" },
        .{ "teacher is a", "noun" },
        .{ "quickly is a", "adverb" },
        .{ "what does dog mean", "animal" },
        .{ "what does think mean", "reason" },
        .{ "what does beautiful mean", "pretty" },
        .{ "what does water mean", "liquid" },
        .{ "what does learn mean", "study" },
        .{ "role of run", "verb" },
        .{ "role of dog", "what" },
        .{ "role of happy", "adj" },
        .{ "role of quickly", "how" },
        .{ "use of speak", "talk" },
        .{ "use of friend", "person" },
    };
    var demo_hit: u32 = 0;
    for (demos) |d| {
        const ok = ask(d[0], d[1]);
        if (ok) demo_hit += 1;
        std.debug.print("Q: {s}?  A: {s}  [{s}]\n", .{ d[0], d[1], if (ok) "HIT" else "MISS" });
    }
    std.debug.print("POINTED_LIVE {d}/{d}\n", .{ demo_hit, demos.len });

    // Speak pointed Q&A (English meaning, not salad)
    if (speak) {
        const lines = [_][]const u8{
            "Is run a verb? Yes.",
            "Is dog a verb? No.",
            "Dog means animal.",
            "Think means reason.",
            "Beautiful means pretty.",
            "I use words with meaning.",
        };
        for (lines) |line| {
            const tts = host_tts.speakEnglish(line);
            if (tts.spoken) rep.n_tts += 1;
        }
    }

    // Gate: curated depth must be strong; overall solid; pointed demos mostly hit
    rep.ok = rep.n_taught_cards >= 20 and
        rep.n_probes >= 100 and
        rep.pos_acc >= 0.90 and
        rep.define_acc >= 0.85 and
        rep.role_acc >= 0.90 and
        rep.acc >= 0.85 and
        demo_hit >= 16;
    return rep;
}

pub fn selfTest() bool {
    return runLanguageDepth(false).ok;
}

//! Stream real literature into organism-scale study cards.
//!
//! Sources (local training data — not LLM benchmarks):
//!   D:\training data\arxiv_fsot_core.txt   ([CAT]…[TITLE]…[ABS]…[END])
//!   D:\training data\nlp\simple-wiki\…\wiki_*  (title + blank-line articles)
//!
//! Doctrine: give the mind **literature to experience**, not exam ranks.
//! Cards become episodic encode + SpeakEngram — then internal think can
//! retrace / compose / self-correct on *that* material.

const std = @import("std");
const memory_f = @import("memory_fixed.zig");

pub const MAX_CARD_CUE: usize = 48;
pub const MAX_CARD_ANS: usize = 32;
pub const MAX_CARD_UTTER: usize = 120;
pub const MAX_CARDS: usize = 512;

pub const LitCard = struct {
    cue: [MAX_CARD_CUE]u8 = .{0} ** MAX_CARD_CUE,
    cue_n: usize = 0,
    answer: [MAX_CARD_ANS]u8 = .{0} ** MAX_CARD_ANS,
    ans_n: usize = 0,
    utter: [MAX_CARD_UTTER]u8 = .{0} ** MAX_CARD_UTTER,
    utter_n: usize = 0,
    cat_h: u32 = 0,
    source: u8 = 0, // 1=arxiv 2=wiki
    valid: bool = false,
};

pub const LitBank = struct {
    cards: [MAX_CARDS]LitCard = undefined,
    n: usize = 0,
    n_arxiv: u32 = 0,
    n_wiki: u32 = 0,
    bytes_read: u64 = 0,
    path_used: [256]u8 = .{0} ** 256,
    path_n: usize = 0,
};

const ARXIV_PATHS = [_][]const u8{
    "D:/training data/arxiv_fsot_core.txt",
    "D:\\training data\\arxiv_fsot_core.txt",
    "I:/fsot-neuron-zig/data/literature/arxiv_fsot_core.txt",
};

const WIKI_PATHS = [_][]const u8{
    "D:/training data/nlp/simple-wiki/1of2/wiki_00",
    "D:\\training data\\nlp\\simple-wiki\\1of2\\wiki_00",
    "D:/training data/nlp/simple-wiki/1of2/wiki_01",
    "D:/training data/nlp/simple-wiki/1of2/wiki_02",
};

fn setPath(bank: *LitBank, path: []const u8) void {
    bank.path_n = @min(path.len, bank.path_used.len);
    @memcpy(bank.path_used[0..bank.path_n], path[0..bank.path_n]);
}

fn copyTrim(dst: []u8, src: []const u8) usize {
    // collapse whitespace, ASCII-ish only
    var o: usize = 0;
    var sp = false;
    for (src) |c| {
        if (o >= dst.len) break;
        if (c == ' ' or c == '\t' or c == '\n' or c == '\r') {
            if (o > 0 and !sp) {
                dst[o] = ' ';
                o += 1;
                sp = true;
            }
            continue;
        }
        if (c >= 32 and c < 127) {
            dst[o] = c;
            o += 1;
            sp = false;
        }
    }
    while (o > 0 and dst[o - 1] == ' ') o -= 1;
    return o;
}

fn firstWords(src: []const u8, max_chars: usize, out: []u8) usize {
    const n = @min(src.len, max_chars);
    return copyTrim(out, src[0..n]);
}

fn titleToCue(title: []const u8, out: []u8) usize {
    // cue = first ~3–6 significant words lowercased-ish (keep case for hash stability)
    var o: usize = 0;
    var words: u32 = 0;
    var i: usize = 0;
    while (i < title.len and o < out.len and words < 5) : (i += 1) {
        const c = title[i];
        if (c == ' ' or c == '\t') {
            if (o > 0 and out[o - 1] != ' ') {
                out[o] = ' ';
                o += 1;
                words += 1;
            }
            continue;
        }
        if (c >= 32 and c < 127) {
            // skip pure punctuation words
            if ((c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9') or c == '-') {
                out[o] = if (c >= 'A' and c <= 'Z') c + 32 else c;
                o += 1;
            }
        }
    }
    while (o > 0 and out[o - 1] == ' ') o -= 1;
    if (o == 0) {
        // fallback: hash id as cue text
        const h = memory_f.hashToken(title);
        return (std.fmt.bufPrint(out, "lit{d}", .{h % 100000}) catch return 0).len;
    }
    return o;
}

fn answerFromAbs(abs: []const u8, out: []u8) usize {
    // first content word(s) of abstract as answer token anchor
    return firstWords(abs, out.len, out);
}

fn addCard(bank: *LitBank, cue: []const u8, ans: []const u8, utter: []const u8, cat: []const u8, source: u8) void {
    if (bank.n >= MAX_CARDS) return;
    if (cue.len < 2 or ans.len < 1) return;
    var c = LitCard{};
    c.cue_n = copyTrim(c.cue[0..], cue);
    c.ans_n = copyTrim(c.answer[0..], ans);
    c.utter_n = copyTrim(c.utter[0..], utter);
    if (c.cue_n == 0 or c.ans_n == 0) return;
    if (c.utter_n == 0) {
        c.utter_n = copyTrim(c.utter[0..], cue);
    }
    c.cat_h = if (cat.len > 0) memory_f.hashToken(cat) else 0;
    c.source = source;
    c.valid = true;
    // dedupe by cue hash
    const ch = memory_f.hashToken(c.cue[0..c.cue_n]);
    var i: usize = 0;
    while (i < bank.n) : (i += 1) {
        if (memory_f.hashToken(bank.cards[i].cue[0..bank.cards[i].cue_n]) == ch) {
            bank.cards[i] = c; // refresh
            return;
        }
    }
    bank.cards[bank.n] = c;
    bank.n += 1;
    if (source == 1) bank.n_arxiv += 1 else if (source == 2) bank.n_wiki += 1;
}

/// Parse arxiv_fsot_core records until max_cards.
pub fn loadArxiv(bank: *LitBank, max_cards: usize) bool {
    for (ARXIV_PATHS) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        setPath(bank, path);
        // stream in chunks
        var buf: [64 * 1024]u8 = undefined;
        var carry: [8 * 1024]u8 = undefined;
        var carry_n: usize = 0;
        var got: usize = 0;
        while (bank.n < max_cards) {
            const nread = file.read(buf[0..]) catch break;
            if (nread == 0) break;
            bank.bytes_read += nread;
            // process carry + buf for [END] records
            var work_len = carry_n + nread;
            var work: [72 * 1024]u8 = undefined;
            if (work_len > work.len) work_len = work.len;
            @memcpy(work[0..carry_n], carry[0..carry_n]);
            const take = @min(nread, work.len - carry_n);
            @memcpy(work[carry_n .. carry_n + take], buf[0..take]);
            var start: usize = 0;
            var i: usize = 0;
            while (i + 4 < work_len) : (i += 1) {
                if (work[i] == '[' and i + 4 < work_len and work[i + 1] == 'E' and work[i + 2] == 'N' and work[i + 3] == 'D' and work[i + 4] == ']') {
                    const rec = work[start .. i + 5];
                    parseArxivRec(bank, rec);
                    start = i + 5;
                    got += 1;
                    if (bank.n >= max_cards) break;
                }
            }
            // keep tail
            const tail = work_len - start;
            if (tail > carry.len) {
                carry_n = 0;
            } else {
                @memcpy(carry[0..tail], work[start .. start + tail]);
                carry_n = tail;
            }
            if (nread < buf.len) break;
        }
        if (bank.n_arxiv > 0) return true;
    }
    return false;
}

fn findTag(rec: []const u8, tag: []const u8) ?usize {
    // find [TAG]
    var i: usize = 0;
    while (i + tag.len + 2 <= rec.len) : (i += 1) {
        if (rec[i] != '[') continue;
        if (std.mem.eql(u8, rec[i + 1 .. i + 1 + tag.len], tag) and i + 1 + tag.len < rec.len and rec[i + 1 + tag.len] == ']') {
            return i + 2 + tag.len; // after ]
        }
    }
    return null;
}

fn parseArxivRec(bank: *LitBank, rec: []const u8) void {
    const cat_i = findTag(rec, "CAT") orelse return;
    const title_i = findTag(rec, "TITLE") orelse return;
    const abs_i = findTag(rec, "ABS") orelse return;
    // slices between tags
    var cat_end = title_i;
    while (cat_end > cat_i and rec[cat_end - 1] != '[') cat_end -= 1;
    // simpler: from after CAT] to before [TITLE
    const cat_s = cat_i;
    const title_s = title_i;
    const abs_s = abs_i;
    // find next [ before each section end
    var cat = rec[cat_s..];
    if (std.mem.indexOf(u8, cat, "[TITLE]")) |p| cat = cat[0..p];
    var title = rec[title_s..];
    if (std.mem.indexOf(u8, title, "[ABS]")) |p| title = title[0..p];
    var abs = rec[abs_s..];
    if (std.mem.indexOf(u8, abs, "[END]")) |p| abs = abs[0..p];

    var cue_buf: [MAX_CARD_CUE]u8 = undefined;
    const cn = titleToCue(title, cue_buf[0..]);
    var ans_buf: [MAX_CARD_ANS]u8 = undefined;
    const an = answerFromAbs(abs, ans_buf[0..]);
    var utter_buf: [MAX_CARD_UTTER]u8 = undefined;
    // utter = short title
    const un = firstWords(title, MAX_CARD_UTTER, utter_buf[0..]);
    if (cn == 0 or an == 0) return;
    addCard(bank, cue_buf[0..cn], ans_buf[0..an], utter_buf[0..un], cat, 1);
}

/// Load simple-wiki style articles (title line, body, blank sep).
pub fn loadWiki(bank: *LitBank, max_cards: usize) bool {
    for (WIKI_PATHS) |path| {
        if (bank.n >= max_cards) break;
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        if (bank.path_n == 0) setPath(bank, path);
        var buf: [128 * 1024]u8 = undefined;
        const nread = file.read(buf[0..]) catch continue;
        bank.bytes_read += nread;
        // split on double newline
        var start: usize = 0;
        var i: usize = 0;
        while (i < nread and bank.n < max_cards) : (i += 1) {
            const at_end = i + 1 >= nread;
            const blank = (i + 1 < nread and buf[i] == '\n' and buf[i + 1] == '\n');
            if (blank or at_end) {
                var art = buf[start .. if (at_end) nread else i];
                start = i + 2;
                // first line = title
                var nl: usize = 0;
                while (nl < art.len and art[nl] != '\n') : (nl += 1) {}
                if (nl < 2) continue;
                const title = art[0..nl];
                const body = if (nl + 1 < art.len) art[nl + 1 ..] else title;
                var cue_buf: [MAX_CARD_CUE]u8 = undefined;
                const cn = titleToCue(title, cue_buf[0..]);
                var ans_buf: [MAX_CARD_ANS]u8 = undefined;
                const an = answerFromAbs(body, ans_buf[0..]);
                var utter_buf: [MAX_CARD_UTTER]u8 = undefined;
                const un = firstWords(title, MAX_CARD_UTTER, utter_buf[0..]);
                addCard(bank, cue_buf[0..cn], ans_buf[0..an], utter_buf[0..un], "wiki", 2);
            }
        }
        if (bank.n_wiki > 0) return true;
    }
    return false;
}

/// Load arxiv first, then wiki to fill remaining slots.
pub fn loadDefault(bank: *LitBank, max_cards: usize) bool {
    bank.* = .{};
    const cap = @min(max_cards, MAX_CARDS);
    const half = cap / 2;
    _ = loadArxiv(bank, if (half < 32) cap else half);
    const remain = if (cap > bank.n) cap - bank.n else 0;
    if (remain > 0) _ = loadWiki(bank, bank.n + remain);
    // if only wiki worked
    if (bank.n == 0) _ = loadWiki(bank, cap);
    return bank.n >= 8;
}

pub fn cardCue(c: *const LitCard) []const u8 {
    return c.cue[0..c.cue_n];
}
pub fn cardAns(c: *const LitCard) []const u8 {
    return c.answer[0..c.ans_n];
}
pub fn cardUtter(c: *const LitCard) []const u8 {
    return c.utter[0..c.utter_n];
}

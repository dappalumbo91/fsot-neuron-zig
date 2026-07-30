//! Study tool — query a concept the mind does not yet know.
//!
//! Curriculum spirit (FSOT Physical Archive / SR-ITE dynamic learning):
//!   unknown → seek → extract definition → retain chain
//!
//! Order of authority (local first, then live credential-free APIs):
//!   1) embedded micro lexicon
//!   2) data/lexicon/en_dictionary.jsonl (repo)
//!   3) D:\training data simple-wiki shards
//!   4) D:\training data arxiv_fsot_core.txt
//!   5) I:\FSOT-Physical-Archive openalex cache + oracle streams
//!   6) optional live Wikipedia REST summary (credential-free)
//!
//! NOT an LLM. Returns a short definition string for encode→engram.

const std = @import("std");
const memory_f = @import("memory_fixed.zig");
const builtin = @import("builtin");

pub const MAX_DEF: usize = 160;
pub const MAX_SRC: usize = 48;

pub const QueryHit = struct {
    found: bool = false,
    def_n: usize = 0,
    def: [MAX_DEF]u8 = .{0} ** MAX_DEF,
    source: [MAX_SRC]u8 = .{0} ** MAX_SRC,
    source_n: usize = 0,
    /// how we found it
    via: []const u8 = "none",
};

fn setSrc(hit: *QueryHit, s: []const u8) void {
    hit.source_n = @min(s.len, hit.source.len);
    @memcpy(hit.source[0..hit.source_n], s[0..hit.source_n]);
}

fn copyDef(hit: *QueryHit, s: []const u8) void {
    // collapse whitespace; drop arxiv markup tags [END] [CAT] [TITLE] [ABS]
    var o: usize = 0;
    var sp = false;
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (o >= hit.def.len) break;
        const c = s[i];
        if (c == '[') {
            // skip [TAG]
            var j = i + 1;
            while (j < s.len and s[j] != ']') : (j += 1) {}
            if (j < s.len) {
                i = j;
                continue;
            }
        }
        if (c == ' ' or c == '\t' or c == '\n' or c == '\r') {
            if (o > 0 and !sp) {
                hit.def[o] = ' ';
                o += 1;
                sp = true;
            }
            continue;
        }
        if (c >= 32 and c < 127) {
            hit.def[o] = c;
            o += 1;
            sp = false;
        }
    }
    while (o > 0 and hit.def[o - 1] == ' ') o -= 1;
    hit.def_n = o;
    hit.found = o >= 8;
}

fn lowerEq(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, 0..) |c, i| {
        const x = if (c >= 'A' and c <= 'Z') c + 32 else c;
        const y = if (b[i] >= 'A' and b[i] <= 'Z') b[i] + 32 else b[i];
        if (x != y) return false;
    }
    return true;
}

fn containsLower(hay: []const u8, needle: []const u8) bool {
    if (needle.len == 0 or hay.len < needle.len) return false;
    var i: usize = 0;
    while (i + needle.len <= hay.len) : (i += 1) {
        if (lowerEq(hay[i .. i + needle.len], needle)) return true;
    }
    return false;
}

/// Tiny always-on seed (offline smoke) — not a substitute for literature.
fn queryEmbedded(term: []const u8, hit: *QueryHit) bool {
    const pairs = [_]struct { []const u8, []const u8 }{
        .{ "table", "a flat surface with legs used to put things on" },
        .{ "chair", "a seat with a back for one person" },
        .{ "water", "clear liquid that living things drink" },
        .{ "sun", "the star that lights the day" },
        .{ "dog", "a domestic animal that is a pet" },
        .{ "neuron", "a nerve cell that carries signals in the brain" },
        .{ "brain", "the organ that thinks and controls the body" },
        .{ "gravity", "the force that pulls masses together" },
        .{ "light", "what we see with our eyes from sources like the sun" },
        .{ "plant", "a living thing that grows and needs sun and water" },
    };
    for (pairs) |p| {
        if (lowerEq(p[0], term)) {
            copyDef(hit, p[1]);
            setSrc(hit, "embedded");
            hit.via = "embedded";
            return hit.found;
        }
    }
    return false;
}

fn queryDictionaryFile(term: []const u8, hit: *QueryHit) bool {
    const paths = [_][]const u8{
        "data/lexicon/en_dictionary.jsonl",
        "../data/lexicon/en_dictionary.jsonl",
        "I:/fsot-neuron-zig/data/lexicon/en_dictionary.jsonl",
        "I:/fsot nuron/data/lexicon/en_dictionary.jsonl",
    };
    for (paths) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        var buf: [256 * 1024]u8 = undefined;
        const n = file.read(buf[0..]) catch continue;
        // lines: {"word":"...","gloss":"..."} or word\tgloss
        var start: usize = 0;
        var i: usize = 0;
        while (i <= n) : (i += 1) {
            if (i == n or buf[i] == '\n') {
                const line = buf[start..i];
                start = i + 1;
                if (line.len < 5) continue;
                // jsonl rough parse
                if (std.mem.indexOf(u8, line, term)) |_| {
                    // require word field near term
                    if (std.mem.indexOf(u8, line, "\"word\"")) |wp| {
                        _ = wp;
                        // extract gloss
                        if (std.mem.indexOf(u8, line, "\"gloss\"")) |gp| {
                            var j = gp + 7;
                            while (j < line.len and line[j] != '"') : (j += 1) {}
                            if (j < line.len) j += 1;
                            const g0 = j;
                            while (j < line.len and line[j] != '"') : (j += 1) {}
                            if (j > g0) {
                                // verify word equals term
                                if (std.mem.indexOf(u8, line, "\"word\"")) |wpos| {
                                    var k = wpos + 6;
                                    while (k < line.len and line[k] != '"') : (k += 1) {}
                                    if (k < line.len) k += 1;
                                    const w0 = k;
                                    while (k < line.len and line[k] != '"') : (k += 1) {}
                                    if (k > w0 and lowerEq(line[w0..k], term)) {
                                        copyDef(hit, line[g0..j]);
                                        setSrc(hit, "dictionary");
                                        hit.via = "dictionary";
                                        return hit.found;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return false;
}

fn queryWikiFiles(term: []const u8, hit: *QueryHit) bool {
    const paths = [_][]const u8{
        "D:/training data/nlp/simple-wiki/1of2/wiki_00",
        "D:/training data/nlp/simple-wiki/1of2/wiki_01",
        "D:/training data/nlp/simple-wiki/1of2/wiki_02",
        "D:/training data/nlp/simple-wiki/1of2/wiki_03",
        "D:/training data/nlp/simple-wiki/1of2/wiki_04",
    };
    for (paths) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        var buf: [256 * 1024]u8 = undefined;
        const n = file.read(buf[0..]) catch continue;
        var start: usize = 0;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            const blank = (i + 1 < n and buf[i] == '\n' and buf[i + 1] == '\n');
            const at_end = i + 1 >= n;
            if (blank or at_end) {
                var art = buf[start..if (at_end) n else i];
                start = i + 2;
                var nl: usize = 0;
                while (nl < art.len and art[nl] != '\n') : (nl += 1) {}
                if (nl < 1) continue;
                const title = art[0..nl];
                // STRICT: title must equal term (or title is single-word equal). No fuzzy contains —
                // "name" matching "April" article via "name" in body/title caused April etymology loops.
                var title_trim = title;
                while (title_trim.len > 0 and title_trim[0] == ' ') title_trim = title_trim[1..];
                while (title_trim.len > 0 and title_trim[title_trim.len - 1] == ' ') title_trim = title_trim[0 .. title_trim.len - 1];
                if (!lowerEq(title_trim, term)) continue;
                const body = if (nl + 1 < art.len) art[nl + 1 ..] else title;
                // first useful sentence (skip "It is unclear…" dead-ends)
                var end: usize = @min(body.len, 140);
                var j: usize = 0;
                while (j < end) : (j += 1) {
                    if (body[j] == '.' and j > 20) {
                        end = j + 1;
                        break;
                    }
                }
                var sent = body[0..end];
                // if first sentence is unhelpful, try next sentence
                if (containsLower(sent, "unclear") or (containsLower(sent, "possibly") and sent.len < 40)) {
                    var k = end;
                    while (k < body.len and (body[k] == ' ' or body[k] == '\n')) : (k += 1) {}
                    var k2 = k;
                    while (k2 < body.len and k2 - k < 140) : (k2 += 1) {
                        if (body[k2] == '.' and k2 - k > 20) {
                            k2 += 1;
                            break;
                        }
                    }
                    if (k2 > k) sent = body[k..k2];
                }
                if (containsLower(sent, "unclear as to where")) continue;
                copyDef(hit, sent);
                setSrc(hit, "simple-wiki");
                hit.via = "simple-wiki";
                return hit.found;
            }
        }
    }
    return false;
}

fn queryArxivCore(term: []const u8, hit: *QueryHit) bool {
    const paths = [_][]const u8{
        "D:/training data/arxiv_fsot_core.txt",
        "I:/FSOT-Physical-Archive/01_SR-ITE-USB-Original/6_unified_oracle/stream_arxiv_science.txt",
        "I:/FSOT-Physical-Archive/01_SR-ITE-USB-Original/6_unified_oracle/stream_physics.txt",
        "I:/FSOT-Physical-Archive/01_SR-ITE-USB-Original/6_unified_oracle/stream_math.txt",
        "I:/FSOT-Physical-Archive/01_SR-ITE-USB-Original/6_unified_oracle/stream_bio.txt",
    };
    for (paths) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        // read first 512KB for search (avoid huge stack)
        var buf: [512 * 1024]u8 = undefined;
        const n = file.read(buf[0..]) catch continue;
        if (!containsLower(buf[0..n], term)) continue;
        // find [TITLE] near term or [ABS]
        if (std.mem.indexOf(u8, buf[0..n], term)) |pos| {
            // expand to a window
            var a = if (pos > 80) pos - 80 else 0;
            const b = @min(n, pos + 120);
            // snap to sentence
            while (a < pos and buf[a] != '.' and buf[a] != ']') : (a += 1) {}
            if (a < pos and (buf[a] == '.' or buf[a] == ']')) a += 1;
            while (a < b and (buf[a] == ' ' or buf[a] == '\n')) : (a += 1) {}
            copyDef(hit, buf[a..b]);
            setSrc(hit, "arxiv-local");
            hit.via = "arxiv-local";
            if (hit.found) return true;
        }
    }
    return false;
}

fn queryOpenAlexCache(term: []const u8, hit: *QueryHit) bool {
    const paths = [_][]const u8{
        "I:/FSOT-Physical-Archive/03_FSOT-PublicData/openalex/openalex_cache.json",
    };
    for (paths) |path| {
        const file = std.fs.cwd().openFile(path, .{}) catch continue;
        defer file.close();
        var buf: [512 * 1024]u8 = undefined;
        const n = file.read(buf[0..]) catch continue;
        if (!containsLower(buf[0..n], term)) continue;
        // pull a "title": "..." near term
        if (std.mem.indexOf(u8, buf[0..n], "\"title\"")) |tp| {
            var j = tp + 7;
            while (j < n and buf[j] != '"') : (j += 1) {}
            if (j < n) j += 1;
            const t0 = j;
            while (j < n and buf[j] != '"') : (j += 1) {}
            if (j > t0 and containsLower(buf[t0..j], term)) {
                copyDef(hit, buf[t0..j]);
                setSrc(hit, "openalex-cache");
                hit.via = "openalex-cache";
                return hit.found;
            }
        }
        // any window
        if (std.mem.indexOf(u8, buf[0..n], term)) |pos| {
            const a = if (pos > 40) pos - 40 else 0;
            const b = @min(n, pos + 80);
            copyDef(hit, buf[a..b]);
            setSrc(hit, "openalex-cache");
            hit.via = "openalex-cache";
            return hit.found;
        }
    }
    return false;
}

/// Live Wikipedia REST summary (credential-free). Windows: uses PowerShell.
fn queryWikipediaLive(term: []const u8, hit: *QueryHit) bool {
    if (builtin.os.tag != .windows) return false;
    if (term.len == 0 or term.len > 40) return false;
    // sanitize term for URL (spaces → _)
    var url_term: [48]u8 = undefined;
    var un: usize = 0;
    for (term) |c| {
        if (un >= url_term.len) break;
        if (c == ' ') {
            url_term[un] = '_';
            un += 1;
        } else if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_' or c == '-') {
            url_term[un] = c;
            un += 1;
        }
    }
    if (un == 0) return false;

    var cmd_buf: [256]u8 = undefined;
    const cmd = std.fmt.bufPrint(
        cmd_buf[0..],
        "powershell -NoProfile -NonInteractive -Command \"try {{ (Invoke-RestMethod -Uri 'https://en.wikipedia.org/api/rest_v1/page/summary/{s}' -TimeoutSec 8).extract }} catch {{ '' }}\"",
        .{url_term[0..un]},
    ) catch return false;

    var child = std.process.Child.init(&.{ "cmd", "/C", cmd }, std.heap.page_allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;
    child.spawn() catch return false;
    var out_buf: [512]u8 = undefined;
    const stdout = child.stdout orelse return false;
    const nr = stdout.read(out_buf[0..]) catch 0;
    _ = child.wait() catch {};
    if (nr < 8) return false;
    // trim
    var s = out_buf[0..nr];
    while (s.len > 0 and (s[s.len - 1] == '\n' or s[s.len - 1] == '\r')) s = s[0 .. s.len - 1];
    if (s.len < 8) return false;
    copyDef(hit, s);
    setSrc(hit, "wikipedia-live");
    hit.via = "wikipedia-live";
    return hit.found;
}

/// Full tool: local archive first, optional live wiki last.
pub fn queryConcept(term: []const u8, allow_live: bool) QueryHit {
    var hit: QueryHit = .{};
    if (term.len == 0) return hit;

    if (queryEmbedded(term, &hit)) return hit;
    if (queryDictionaryFile(term, &hit)) return hit;
    if (queryWikiFiles(term, &hit)) return hit;
    if (queryOpenAlexCache(term, &hit)) return hit;
    if (queryArxivCore(term, &hit)) return hit;
    if (allow_live and queryWikipediaLive(term, &hit)) return hit;
    hit.via = "miss";
    return hit;
}

pub fn selfTest() bool {
    const h = queryConcept("table", false);
    return h.found and h.def_n >= 8;
}

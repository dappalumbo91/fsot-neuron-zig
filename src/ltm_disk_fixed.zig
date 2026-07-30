//! Long-term memory on disk — hippocampus → cortex analogue.
//!
//! Architecture:
//!   STM (short-term) = hot working pools in RAM (CPU/GPU later for thought compute)
//!   LTM (long-term)  = append-only pages under data/ltm/ (disk organ)
//!
//! Doctrine: compile-time array sizes are **STM working windows**, not knowledge ceilings.
//! When STM is full we **spill** oldest/cold entries to disk and free slots so growth continues.
//! A full STM is never a reason to stop learning.

const std = @import("std");

pub const LTM_DIR = "data/ltm";
pub const GROWN_PATH = "data/ltm/grown.jsonl";
pub const ENGRAM_PATH = "data/ltm/engrams.jsonl";
pub const EPISODE_PATH = "data/ltm/episodes.jsonl";

/// FNV-1a — local so this module does not depend on memory_fixed (avoids import cycles).
fn hashToken(bytes: []const u8) u32 {
    var h: u32 = 2166136261;
    for (bytes) |c| {
        h ^= c;
        h *%= 16777619;
    }
    return if (h == 0) 1 else h;
}

pub const Stats = struct {
    grown_spilled: u64 = 0,
    engram_spilled: u64 = 0,
    episode_spilled: u64 = 0,
    spill_events: u32 = 0,
    /// Cold → hot: records loaded from disk LTM back into STM
    warm_recalls: u64 = 0,
    io_errors: u32 = 0,
};

/// Parsed grown concept from LTM (cue/ans/utter).
pub const GrownRec = struct {
    cue: [48]u8 = .{0} ** 48,
    cue_n: usize = 0,
    ans: [40]u8 = .{0} ** 40,
    ans_n: usize = 0,
    utter: [120]u8 = .{0} ** 120,
    utter_n: usize = 0,
    valid: bool = false,
};

var stats: Stats = .{};

pub fn getStats() Stats {
    return stats;
}

pub fn resetStats() void {
    stats = .{};
}

pub fn ensureDir() void {
    std.fs.cwd().makePath(LTM_DIR) catch {};
}

fn scrub(src: []const u8, dst: []u8) usize {
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

fn appendLine(path: []const u8, line: []const u8) bool {
    ensureDir();
    const file = std.fs.cwd().openFile(path, .{ .mode = .write_only }) catch blk: {
        break :blk std.fs.cwd().createFile(path, .{}) catch {
            stats.io_errors += 1;
            return false;
        };
    };
    defer file.close();
    file.seekFromEnd(0) catch {
        stats.io_errors += 1;
        return false;
    };
    file.writeAll(line) catch {
        stats.io_errors += 1;
        return false;
    };
    file.sync() catch {};
    return true;
}

/// Spill one grown concept (cue/ans/utter) to disk LTM.
pub fn spillGrown(cue: []const u8, ans: []const u8, utter: []const u8) bool {
    var cbuf: [48]u8 = undefined;
    var abuf: [40]u8 = undefined;
    var ubuf: [120]u8 = undefined;
    const cn = scrub(cue, cbuf[0..]);
    const an = scrub(ans, abuf[0..]);
    const un = scrub(utter, ubuf[0..]);
    var line: [384]u8 = undefined;
    const out = std.fmt.bufPrint(
        line[0..],
        "{{\"kind\":\"grown\",\"cue_h\":{d},\"cue\":\"{s}\",\"ans\":\"{s}\",\"utter\":\"{s}\"}}\n",
        .{ hashToken(cue), cbuf[0..cn], abuf[0..an], ubuf[0..un] },
    ) catch {
        stats.io_errors += 1;
        return false;
    };
    if (!appendLine(GROWN_PATH, out)) return false;
    stats.grown_spilled += 1;
    return true;
}

/// Spill a speak engram (motor memory) to disk LTM — cue/ans text for warm re-encode.
pub fn spillEngram(
    ep_id: u32,
    cue_h: u32,
    ans_h: u32,
    phrase: []const u8,
    cue: []const u8,
    ans: []const u8,
) bool {
    var pbuf: [96]u8 = undefined;
    var cbuf: [40]u8 = undefined;
    var abuf: [40]u8 = undefined;
    const pn = scrub(phrase, pbuf[0..]);
    const cn = scrub(cue, cbuf[0..]);
    const an = scrub(ans, abuf[0..]);
    var line: [384]u8 = undefined;
    const out = std.fmt.bufPrint(
        line[0..],
        "{{\"kind\":\"engram\",\"ep_id\":{d},\"cue_h\":{d},\"ans_h\":{d},\"cue\":\"{s}\",\"ans\":\"{s}\",\"phrase\":\"{s}\"}}\n",
        .{ ep_id, cue_h, ans_h, cbuf[0..cn], abuf[0..an], pbuf[0..pn] },
    ) catch {
        stats.io_errors += 1;
        return false;
    };
    if (!appendLine(ENGRAM_PATH, out)) return false;
    stats.engram_spilled += 1;
    return true;
}

/// Parsed speak engram from LTM (for cold → hot warm).
pub const EngramRec = struct {
    ep_id: u32 = 0,
    cue: [40]u8 = .{0} ** 40,
    cue_n: usize = 0,
    ans: [40]u8 = .{0} ** 40,
    ans_n: usize = 0,
    phrase: [96]u8 = .{0} ** 96,
    phrase_n: usize = 0,
    valid: bool = false,
};

pub fn parseEngramLine(line: []const u8, out: *EngramRec) bool {
    out.* = .{};
    if (line.len < 12) return false;
    if (std.mem.indexOf(u8, line, "\"kind\":\"engram\"") == null and
        std.mem.indexOf(u8, line, "\"phrase\"") == null) return false;
    out.cue_n = extractJsonStr(line, "cue", out.cue[0..]);
    out.ans_n = extractJsonStr(line, "ans", out.ans[0..]);
    out.phrase_n = extractJsonStr(line, "phrase", out.phrase[0..]);
    // legacy lines: phrase only — try to split "X is Y" / "X: Y"
    if (out.cue_n < 2 and out.phrase_n >= 4) {
        if (std.mem.indexOf(u8, out.phrase[0..out.phrase_n], " is ")) |sp| {
            out.cue_n = copyField(out.cue[0..], out.phrase[0..sp]);
            const rest = out.phrase[sp + 4 .. out.phrase_n];
            out.ans_n = copyField(out.ans[0..], rest[0..@min(rest.len, out.ans.len)]);
        } else if (std.mem.indexOfScalar(u8, out.phrase[0..out.phrase_n], ':')) |col| {
            out.cue_n = copyField(out.cue[0..], out.phrase[0..col]);
            var r = col + 1;
            while (r < out.phrase_n and out.phrase[r] == ' ') r += 1;
            out.ans_n = copyField(out.ans[0..], out.phrase[r..out.phrase_n]);
        }
    }
    if (out.cue_n < 2) return false;
    if (out.ans_n < 1) {
        out.ans_n = copyField(out.ans[0..], out.cue[0..out.cue_n]);
    }
    if (out.phrase_n < 2) {
        out.phrase_n = copyField(out.phrase[0..], out.cue[0..out.cue_n]);
    }
    out.valid = true;
    return true;
}

/// Sample one engram record from LTM by seed (deterministic pick among lines).
pub fn sampleEngram(seed: u32, out: *EngramRec) bool {
    out.* = .{};
    const nlines = countLines(ENGRAM_PATH);
    if (nlines == 0) return false;
    const target: u64 = @as(u64, seed) % nlines;
    const file = std.fs.cwd().openFile(ENGRAM_PATH, .{}) catch {
        stats.io_errors += 1;
        return false;
    };
    defer file.close();
    var buf: [512]u8 = undefined;
    var line_i: u64 = 0;
    var pos: usize = 0;
    while (true) {
        const nr = file.read(buf[pos..]) catch break;
        if (nr == 0 and pos == 0) break;
        const total = pos + nr;
        var i: usize = 0;
        var line_start: usize = 0;
        while (i < total) : (i += 1) {
            if (buf[i] == '\n') {
                const line = buf[line_start..i];
                if (line_i == target) {
                    const ok = parseEngramLine(line, out);
                    if (ok) stats.warm_recalls += 1;
                    return ok;
                }
                line_i += 1;
                line_start = i + 1;
            }
        }
        if (nr == 0) {
            if (line_start < total and line_i == target) {
                const ok = parseEngramLine(buf[line_start..total], out);
                if (ok) stats.warm_recalls += 1;
                return ok;
            }
            break;
        }
        const rem = total - line_start;
        if (rem > 0 and line_start > 0) {
            @memcpy(buf[0..rem], buf[line_start .. line_start + rem]);
        }
        pos = rem;
        if (pos >= buf.len) pos = 0;
    }
    return false;
}

/// Spill one episode (id + tokens + raw Fixed fingerprint) to disk LTM.
/// `fp` is SCALE-preserved i64 lattice values — no float.
pub fn spillEpisode(id: u32, slot_mask: u8, tokens: *const [6]u32, fp: []const i64) bool {
    if (id == 0) return false;
    var line: [2048]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&line);
    const w = fbs.writer();
    w.print(
        "{{\"kind\":\"episode\",\"id\":{d},\"mask\":{d},\"t\":[{d},{d},{d},{d},{d},{d}],\"fp\":[",
        .{
            id,
            slot_mask,
            tokens[0],
            tokens[1],
            tokens[2],
            tokens[3],
            tokens[4],
            tokens[5],
        },
    ) catch {
        stats.io_errors += 1;
        return false;
    };
    var i: usize = 0;
    while (i < fp.len) : (i += 1) {
        if (i > 0) w.writeAll(",") catch {};
        w.print("{d}", .{fp[i]}) catch {
            stats.io_errors += 1;
            return false;
        };
    }
    w.writeAll("]}\n") catch {
        stats.io_errors += 1;
        return false;
    };
    if (!appendLine(EPISODE_PATH, fbs.getWritten())) return false;
    stats.episode_spilled += 1;
    return true;
}

pub fn noteSpillEvent() void {
    stats.spill_events += 1;
}

/// Approximate LTM line count for one file (for heartbeat / capacity report).
pub fn countLines(path: []const u8) u64 {
    const file = std.fs.cwd().openFile(path, .{}) catch return 0;
    defer file.close();
    var buf: [8192]u8 = undefined;
    var n: u64 = 0;
    while (true) {
        const nr = file.read(buf[0..]) catch break;
        if (nr == 0) break;
        for (buf[0..nr]) |c| {
            if (c == '\n') n += 1;
        }
    }
    return n;
}

pub fn reportLtmTotals() struct { grown: u64, engrams: u64, episodes: u64 } {
    return .{
        .grown = countLines(GROWN_PATH),
        .engrams = countLines(ENGRAM_PATH),
        .episodes = countLines(EPISODE_PATH),
    };
}

fn copyField(dst: []u8, src: []const u8) usize {
    const n = @min(src.len, dst.len);
    @memcpy(dst[0..n], src[0..n]);
    return n;
}

/// Extract `"key":"value"` from a simple JSONL object (no nested quotes).
fn extractJsonStr(line: []const u8, key: []const u8, out: []u8) usize {
    var pat: [48]u8 = undefined;
    const pn = (std.fmt.bufPrint(pat[0..], "\"{s}\":\"", .{key}) catch return 0).len;
    if (pn >= pat.len) return 0;
    const idx = std.mem.indexOf(u8, line, pat[0..pn]) orelse return 0;
    const start = idx + pn;
    var i = start;
    while (i < line.len and line[i] != '"') : (i += 1) {}
    if (i <= start) return 0;
    return copyField(out, line[start..i]);
}

pub fn parseGrownLine(line: []const u8, out: *GrownRec) bool {
    out.* = .{};
    if (line.len < 10) return false;
    if (std.mem.indexOf(u8, line, "\"kind\":\"grown\"") == null and
        std.mem.indexOf(u8, line, "\"cue\"") == null) return false;
    out.cue_n = extractJsonStr(line, "cue", out.cue[0..]);
    out.ans_n = extractJsonStr(line, "ans", out.ans[0..]);
    out.utter_n = extractJsonStr(line, "utter", out.utter[0..]);
    if (out.cue_n < 2) return false;
    out.valid = true;
    return true;
}

/// Sample one grown record from LTM by seed (deterministic pick among lines).
pub fn sampleGrown(seed: u32, out: *GrownRec) bool {
    out.* = .{};
    const nlines = countLines(GROWN_PATH);
    if (nlines == 0) return false;
    const target: u64 = @as(u64, seed) % nlines;
    const file = std.fs.cwd().openFile(GROWN_PATH, .{}) catch {
        stats.io_errors += 1;
        return false;
    };
    defer file.close();
    var buf: [512]u8 = undefined;
    var line_i: u64 = 0;
    var pos: usize = 0;
    while (true) {
        const nr = file.read(buf[pos..]) catch break;
        if (nr == 0 and pos == 0) break;
        const total = pos + nr;
        var i: usize = 0;
        var line_start: usize = 0;
        while (i < total) : (i += 1) {
            if (buf[i] == '\n') {
                const line = buf[line_start..i];
                if (line_i == target) {
                    const ok = parseGrownLine(line, out);
                    if (ok) stats.warm_recalls += 1;
                    return ok;
                }
                line_i += 1;
                line_start = i + 1;
            }
        }
        if (nr == 0) {
            // last partial line
            if (line_start < total and line_i == target) {
                const ok = parseGrownLine(buf[line_start..total], out);
                if (ok) stats.warm_recalls += 1;
                return ok;
            }
            break;
        }
        // keep remainder
        const rem = total - line_start;
        if (rem > 0 and line_start > 0) {
            @memcpy(buf[0..rem], buf[line_start .. line_start + rem]);
        }
        pos = rem;
        if (pos >= buf.len) pos = 0; // pathological long line — skip
    }
    return false;
}

/// Linear scan LTM grown file for exact cue match (case-sensitive as stored).
pub fn findGrownCue(term: []const u8, out: *GrownRec) bool {
    out.* = .{};
    if (term.len < 2) return false;
    const file = std.fs.cwd().openFile(GROWN_PATH, .{}) catch return false;
    defer file.close();
    var buf: [4096]u8 = undefined;
    var pos: usize = 0;
    while (true) {
        const nr = file.read(buf[pos..]) catch break;
        if (nr == 0 and pos == 0) break;
        const total = pos + nr;
        var i: usize = 0;
        var line_start: usize = 0;
        while (i < total) : (i += 1) {
            if (buf[i] == '\n') {
                const line = buf[line_start..i];
                var rec: GrownRec = .{};
                if (parseGrownLine(line, &rec)) {
                    if (rec.cue_n == term.len and std.mem.eql(u8, rec.cue[0..rec.cue_n], term)) {
                        out.* = rec;
                        stats.warm_recalls += 1;
                        return true;
                    }
                }
                line_start = i + 1;
            }
        }
        if (nr == 0) break;
        const rem = total - line_start;
        if (rem > 0 and line_start > 0) @memcpy(buf[0..rem], buf[line_start .. line_start + rem]);
        pos = if (rem < buf.len) rem else 0;
    }
    return false;
}

pub fn selfTest() bool {
    ensureDir();
    const ok_spill = spillGrown("ltm_probe_cue", "ltm_probe_ans", "ltm is disk long term memory");
    if (!ok_spill or stats.grown_spilled < 1) return false;
    var rec: GrownRec = .{};
    // sample should eventually find something; try find first
    if (!findGrownCue("ltm_probe_cue", &rec)) {
        // try sample a few seeds
        var s: u32 = 0;
        var found = false;
        while (s < 8) : (s += 1) {
            if (sampleGrown(s, &rec) and rec.valid) {
                found = true;
                break;
            }
        }
        if (!found) return false;
    }
    return rec.valid and rec.cue_n >= 2;
}

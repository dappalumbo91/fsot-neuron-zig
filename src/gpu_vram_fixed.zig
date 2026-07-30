//! Full VRAM matrix offload — episode fingerprints → FSOT-GPU consensus kernels.
//!
//! Pipeline:
//!   STM episodes (Fixed fp) → float32 matrix bin → Python worker
//!   → CUDA upload Q=K=V [1,1,S,D] → fsot_attn_lib consensus (no softmax)
//!   → device pairwise top-K → JSON → Zig sleep replay
//!
//! Mind authority stays Fixed lattice. GPU = organ only.
//! Worker: skills/python/vram_offload.py
//! Mode: fsot_mind gpu-vram

const std = @import("std");
const fixed = @import("fixed.zig");
const memory_f = @import("memory_fixed.zig");
const gpu_organ = @import("gpu_organ_fixed.zig");
const Fixed = fixed.Fixed;

/// Same layout as gpu_batch.Pair — kept local to avoid import cycles.
pub const VramPair = struct {
    i: u32 = 0,
    j: u32 = 0,
    cos_sim: Fixed = 0,
    trit_sim: Fixed = 0,
    score: Fixed = 0,
};

pub const MAGIC: u32 = 0x46534F54; // 'FSOT'
pub const VERSION: u32 = 1;
pub const IN_PATH = "data/ltm/vram_in.bin";
pub const OUT_PATH = "data/ltm/vram_out.json";
pub const WORKER = "skills/python/vram_offload.py";

pub const VramReport = struct {
    ok: bool = false,
    n_rows: u32 = 0,
    n_pairs: u32 = 0,
    path: [64]u8 = .{0} ** 64,
    path_n: usize = 0,
    device: [32]u8 = .{0} ** 32,
    device_n: usize = 0,
    ms: u64 = 0,
    used_vram: bool = false,
    error_n: usize = 0,
    err: [120]u8 = .{0} ** 120,
};

fn copyTo(dst: []u8, src: []const u8) usize {
    const n = @min(src.len, dst.len);
    @memcpy(dst[0..n], src[0..n]);
    return n;
}

fn resolvePython(out: []u8) usize {
    const candidates = [_][]const u8{
        "C:\\Users\\damia\\AppData\\Local\\Programs\\Python\\Python314\\python.exe",
        "C:\\Users\\damia\\AppData\\Local\\Programs\\Python\\Python313\\python.exe",
        "C:\\Users\\damia\\AppData\\Local\\Programs\\Python\\Python312\\python.exe",
        "C:\\Users\\damia\\AppData\\Local\\Programs\\Python\\Python311\\python.exe",
        "py",
        "python",
    };
    for (candidates) |c| {
        var child = std.process.Child.init(&.{ c, "-c", "print(1)" }, std.heap.page_allocator);
        child.stdout_behavior = .Ignore;
        child.stderr_behavior = .Ignore;
        const r = child.spawnAndWait() catch continue;
        switch (r) {
            .Exited => |code| if (code == 0) return copyTo(out, c),
            else => continue,
        }
    }
    return 0;
}

/// Export valid episodes as float32 matrix for VRAM worker.
/// Returns number of rows written (0 if none).
pub fn exportEpisodeMatrix(store: *const memory_f.StoreF, path: []const u8) !u32 {
    // collect valid indices (window last 128 for transfer budget)
    var slots: [memory_f.MAX_EPISODES]u32 = undefined;
    var n: usize = 0;
    const start: usize = if (store.n > 128) store.n - 128 else 0;
    var i: usize = start;
    while (i < store.n) : (i += 1) {
        if (!store.episodes[i].valid) continue;
        slots[n] = @intCast(i);
        n += 1;
    }
    if (n < 2) return 0;

    std.fs.cwd().makePath("data/ltm") catch {};
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    var hdr: [16]u8 = undefined;
    // little-endian header
    writeU32(hdr[0..4], MAGIC);
    writeU32(hdr[4..8], VERSION);
    writeU32(hdr[8..12], @intCast(n));
    writeU32(hdr[12..16], @intCast(memory_f.FP_DIM));
    try file.writeAll(hdr[0..]);

    // slot indices
    var sbuf: [4]u8 = undefined;
    var s: usize = 0;
    while (s < n) : (s += 1) {
        writeU32(sbuf[0..], slots[s]);
        try file.writeAll(sbuf[0..]);
    }

    // float32 rows
    var row: [memory_f.FP_DIM]f32 = undefined;
    s = 0;
    while (s < n) : (s += 1) {
        const ep = &store.episodes[slots[s]];
        var d: usize = 0;
        while (d < memory_f.FP_DIM) : (d += 1) {
            row[d] = @floatCast(fixed.toF64(ep.fp[d]));
        }
        try file.writeAll(std.mem.sliceAsBytes(row[0..]));
    }
    return @intCast(n);
}

fn writeU32(buf: []u8, v: u32) void {
    buf[0] = @truncate(v);
    buf[1] = @truncate(v >> 8);
    buf[2] = @truncate(v >> 16);
    buf[3] = @truncate(v >> 24);
}

fn parseF64Loose(s: []const u8) f64 {
    return std.fmt.parseFloat(f64, s) catch 0;
}

fn parseU32Loose(s: []const u8) u32 {
    return std.fmt.parseInt(u32, s, 10) catch 0;
}

/// Very small JSON field extractors (no full parser).
/// Accepts `"key":"value"` or `"key": "value"`.
fn extractStr(json: []const u8, key: []const u8, out: []u8) usize {
    var pat: [48]u8 = undefined;
    const pn = (std.fmt.bufPrint(pat[0..], "\"{s}\":", .{key}) catch return 0).len;
    const idx = std.mem.indexOf(u8, json, pat[0..pn]) orelse return 0;
    var i = idx + pn;
    while (i < json.len and (json[i] == ' ' or json[i] == '\t')) : (i += 1) {}
    if (i >= json.len or json[i] != '"') return 0;
    i += 1;
    const start = i;
    while (i < json.len and json[i] != '"') : (i += 1) {}
    if (i <= start) return 0;
    return copyTo(out, json[start..i]);
}

fn extractBool(json: []const u8, key: []const u8) bool {
    var pat: [40]u8 = undefined;
    const pn = (std.fmt.bufPrint(pat[0..], "\"{s}\":", .{key}) catch return false).len;
    const idx = std.mem.indexOf(u8, json, pat[0..pn]) orelse return false;
    var i = idx + pn;
    while (i < json.len and (json[i] == ' ' or json[i] == '\t')) : (i += 1) {}
    return i + 4 <= json.len and std.mem.eql(u8, json[i .. i + 4], "true");
}

fn extractU64(json: []const u8, key: []const u8) u64 {
    var pat: [40]u8 = undefined;
    const pn = (std.fmt.bufPrint(pat[0..], "\"{s}\":", .{key}) catch return 0).len;
    const idx = std.mem.indexOf(u8, json, pat[0..pn]) orelse return 0;
    var i = idx + pn;
    while (i < json.len and (json[i] == ' ' or json[i] == '\t')) : (i += 1) {}
    var j = i;
    while (j < json.len and json[j] >= '0' and json[j] <= '9') : (j += 1) {}
    if (j <= i) return 0;
    return std.fmt.parseInt(u64, json[i..j], 10) catch 0;
}

/// Parse pairs array objects { "i":N,"j":N,"cos":F,"trit":F }
pub fn parsePairs(json: []const u8, out: []VramPair) usize {
    var n: usize = 0;
    var search_from: usize = 0;
    while (n < out.len) {
        const rest = json[search_from..];
        const pi = std.mem.indexOf(u8, rest, "\"i\":") orelse break;
        const abs = search_from + pi;
        // parse i
        var p = abs + 4;
        while (p < json.len and (json[p] == ' ' or json[p] == '\t')) : (p += 1) {}
        var pe = p;
        while (pe < json.len and json[pe] >= '0' and json[pe] <= '9') : (pe += 1) {}
        const ii = parseU32Loose(json[p..pe]);
        const jkey = std.mem.indexOf(u8, json[pe..], "\"j\":") orelse break;
        p = pe + jkey + 4;
        while (p < json.len and (json[p] == ' ' or json[p] == '\t')) : (p += 1) {}
        pe = p;
        while (pe < json.len and json[pe] >= '0' and json[pe] <= '9') : (pe += 1) {}
        const jj = parseU32Loose(json[p..pe]);
        // cos
        var cos_f: f64 = 0;
        if (std.mem.indexOf(u8, json[pe..], "\"cos\":")) |ck| {
            p = pe + ck + 6;
            while (p < json.len and (json[p] == ' ' or json[p] == '\t')) : (p += 1) {}
            pe = p;
            while (pe < json.len and ((json[pe] >= '0' and json[pe] <= '9') or json[pe] == '.' or json[pe] == '-' or json[pe] == 'e' or json[pe] == 'E' or json[pe] == '+')) : (pe += 1) {}
            cos_f = parseF64Loose(json[p..pe]);
        }
        var trit_f: f64 = 0;
        if (std.mem.indexOf(u8, json[pe..], "\"trit\":")) |tk| {
            p = pe + tk + 7;
            while (p < json.len and (json[p] == ' ' or json[p] == '\t')) : (p += 1) {}
            pe = p;
            while (pe < json.len and ((json[pe] >= '0' and json[pe] <= '9') or json[pe] == '.' or json[pe] == '-' or json[pe] == 'e' or json[pe] == 'E' or json[pe] == '+')) : (pe += 1) {}
            trit_f = parseF64Loose(json[p..pe]);
        }
        // score blend for ranking
        const score_f = 0.6 * cos_f + 0.4 * trit_f;
        out[n] = .{
            .i = ii,
            .j = jj,
            .cos_sim = fixed.fromDecimalStr(if (cos_f >= 0) "0.5" else "0"), // refined below
            .trit_sim = fixed.fromDecimalStr(if (trit_f >= 0) "0.5" else "0"),
            .score = fixed.fromDecimalStr(if (score_f >= 0) "0.5" else "0"),
        };
        // Better: store via fromRatio of scaled integers
        out[n].cos_sim = floatToFixed(cos_f);
        out[n].trit_sim = floatToFixed(trit_f);
        out[n].score = floatToFixed(score_f);
        n += 1;
        search_from = pe;
        if (search_from >= json.len) break;
    }
    return n;
}

fn floatToFixed(x: f64) Fixed {
    // clamp to [-2,2] then scale
    var v = x;
    if (v > 2.0) v = 2.0;
    if (v < -2.0) v = -2.0;
    const scaled: i64 = @intFromFloat(v * 1_000_000_000_000.0);
    return scaled; // Fixed = i64 at SCALE
}

/// Run full VRAM offload: export → worker → parse pairs into `out`.
pub fn findTopPairsVram(store: *const memory_f.StoreF, k: usize, out: []VramPair, rep: *VramReport) usize {
    rep.* = .{};
    const t0 = std.time.milliTimestamp();

    const g = gpu_organ.probe();
    if (!g.present or !g.attn_dll) {
        rep.path_n = copyTo(rep.path[0..], "skip-no-dll");
        rep.ms = elapsed(t0);
        return 0;
    }

    const nrows = exportEpisodeMatrix(store, IN_PATH) catch {
        rep.path_n = copyTo(rep.path[0..], "export-fail");
        rep.error_n = copyTo(rep.err[0..], "exportEpisodeMatrix failed");
        rep.ms = elapsed(t0);
        return 0;
    };
    rep.n_rows = nrows;
    if (nrows < 2) {
        rep.path_n = copyTo(rep.path[0..], "skip-small");
        rep.ok = true;
        rep.ms = elapsed(t0);
        return 0;
    }

    var py: [260]u8 = undefined;
    const pn = resolvePython(py[0..]);
    if (pn == 0) {
        rep.path_n = copyTo(rep.path[0..], "no-python");
        rep.ms = elapsed(t0);
        return 0;
    }

    // k_buf for top_k arg
    var kbuf: [16]u8 = undefined;
    const kstr = std.fmt.bufPrint(kbuf[0..], "{d}", .{k}) catch "8";

    var lab_arg: []const u8 = "";
    if (g.lab_n > 0) {
        lab_arg = g.lab_path[0..g.lab_n];
    }

    var argv: [6][]const u8 = undefined;
    var argc: usize = 0;
    argv[argc] = py[0..pn];
    argc += 1;
    argv[argc] = WORKER;
    argc += 1;
    argv[argc] = IN_PATH;
    argc += 1;
    argv[argc] = OUT_PATH;
    argc += 1;
    argv[argc] = kstr;
    argc += 1;
    if (lab_arg.len > 0) {
        argv[argc] = lab_arg;
        argc += 1;
    }

    var child = std.process.Child.init(argv[0..argc], std.heap.page_allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    child.spawn() catch {
        rep.path_n = copyTo(rep.path[0..], "spawn-fail");
        rep.ms = elapsed(t0);
        return 0;
    };
    // drain
    var sink: [512]u8 = undefined;
    if (child.stdout) |*so| {
        while (true) {
            const nr = so.read(sink[0..]) catch break;
            if (nr == 0) break;
        }
    }
    if (child.stderr) |*se| {
        while (true) {
            const nr = se.read(sink[0..]) catch break;
            if (nr == 0) break;
        }
    }
    const term = child.wait() catch {
        rep.path_n = copyTo(rep.path[0..], "wait-fail");
        rep.ms = elapsed(t0);
        return 0;
    };
    _ = term;

    const file = std.fs.cwd().openFile(OUT_PATH, .{}) catch {
        rep.path_n = copyTo(rep.path[0..], "no-out-json");
        rep.ms = elapsed(t0);
        return 0;
    };
    defer file.close();
    var jbuf: [16 * 1024]u8 = undefined;
    const jn = file.readAll(jbuf[0..]) catch 0;
    const json = jbuf[0..jn];

    rep.ok = extractBool(json, "ok");
    rep.path_n = extractStr(json, "path", rep.path[0..]);
    rep.device_n = extractStr(json, "device", rep.device[0..]);
    rep.ms = extractU64(json, "ms");
    if (rep.ms == 0) rep.ms = elapsed(t0);
    rep.used_vram = std.mem.indexOf(u8, rep.path[0..rep.path_n], "vram") != null or
        std.mem.indexOf(u8, rep.path[0..rep.path_n], "device") != null or
        std.mem.eql(u8, rep.device[0..rep.device_n], "cuda");

    if (!rep.ok) {
        rep.error_n = extractStr(json, "error", rep.err[0..]);
        return 0;
    }

    const np = parsePairs(json, out);
    rep.n_pairs = @intCast(np);
    return np;
}

fn elapsed(t0: i64) u64 {
    const t1 = std.time.milliTimestamp();
    return if (t1 >= t0) @intCast(t1 - t0) else 0;
}

pub fn selfTest() bool {
    std.fs.cwd().access(WORKER, .{}) catch return false;
    const g = gpu_organ.probe();
    return g.parity_ok and (g.attn_dll or g.native_kernel);
}

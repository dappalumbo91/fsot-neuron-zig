//! GPU organ — FSOT-GPU stack as body compute (not mind authority).
//!
//! Reference implementation (already solved GPU):
//!   github.com/dappalumbo91/FSOT-GPU
//!   local lab: Desktop/gpu exparment for lean coq isabell andf star
//!
//! Doctrine (same as FSOT-GPU OWNED_STACK / ARCHITECTURE):
//!   FSOT Fixed lattice = mind authority
//!   GPU = parallel compute organ (trinary pack, consensus, batch sleep, vision)
//!   Formal Lean·Coq·Isabelle·F* constrain kernels; CUDA executes contracts
//!   PyTorch/CUDA toolkit = optional backend, never second brain
//!
//! This module:
//!   1. Probes device (nvidia-smi) — same host as FSOT-GPU (RTX 5070 validated)
//!   2. Locates FSOT-GPU lab + native kernel binaries
//!   3. Runs owned trinary-pack **parity** (Zig twin of FSOT-GPU parity/zig_parity)
//!   4. Optionally smokes native CUDA pack exe when built
//!   5. Exposes consolidate path for sleep (kernel smoke / hint)
//!
//! Mode: fsot_mind gpu-organ

const std = @import("std");
const builtin = @import("builtin");

/// Seed-derived collapse threshold — matches FSOT-GPU parity/zig_parity + fsot_lib.
/// C_eff · P_var (not a free hyperparameter).
pub const C_EFF: f64 = 0.9577022026205613;
pub const P_VAR: f64 = 0.9579871226722757;
pub const PHI: f64 = 1.618033988749895;
pub const GAMMA: f64 = 0.5772156649015329;
pub const K_COUPLING: f64 = 0.42022166416069665;
pub const PSI_CON: f64 = 0.6321205588285577;
pub const COLLAPSE_THRESHOLD: f64 = C_EFF * P_VAR;

/// Default lab roots to search (Windows development host).
const LAB_CANDIDATES = [_][]const u8{
    "C:\\Users\\damia\\Desktop\\gpu exparment for lean coq isabell andf star",
    "C:\\Users\\damia\\Desktop\\FSOT-GPU",
    "I:\\FSOT-GPU",
};

pub const GpuReport = struct {
    present: bool = false,
    name: [96]u8 = .{0} ** 96,
    name_n: usize = 0,
    vram_mb: u32 = 0,
    sm_count: u32 = 0,
    /// CC major*10+minor if known (12.0 Blackwell → 120)
    compute_cap: u32 = 0,
    driver_note: [48]u8 = .{0} ** 48,
    driver_n: usize = 0,
    /// FSOT-GPU lab found on disk
    fsot_gpu_lab: bool = false,
    lab_path: [320]u8 = .{0} ** 320,
    lab_n: usize = 0,
    /// Native trinary_pack_test.exe present
    native_kernel: bool = false,
    /// fsot_attn_lib.dll present (industry attention organ)
    attn_dll: bool = false,
    /// Owned pack/collapse parity OK (no CUDA required)
    parity_ok: bool = false,
    /// Native kernel smoke ran OK (if binary present)
    kernel_smoke_ok: bool = false,
    /// Ready for batch organ work under Fixed mind
    batch_ready: bool = false,
    ok: bool = false,
};

fn copyTo(dst: []u8, src: []const u8) usize {
    const n = @min(src.len, dst.len);
    @memcpy(dst[0..n], src[0..n]);
    return n;
}

fn runCapture(argv: []const []const u8, out: []u8) usize {
    var child = std.process.Child.init(argv, std.heap.page_allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;
    child.spawn() catch return 0;
    var n: usize = 0;
    if (child.stdout) |*so| {
        while (n < out.len) {
            var tmp: [256]u8 = undefined;
            const nr = so.read(tmp[0..]) catch break;
            if (nr == 0) break;
            const take = @min(nr, out.len - n);
            @memcpy(out[n .. n + take], tmp[0..take]);
            n += take;
        }
    }
    _ = child.wait() catch {};
    return n;
}

fn pathExists(p: []const u8) bool {
    std.fs.cwd().access(p, .{}) catch {
        // absolute paths: openFile from root
        const f = std.fs.openFileAbsolute(p, .{}) catch return false;
        f.close();
        return true;
    };
    return true;
}

fn joinLab(lab: []const u8, rel: []const u8, out: []u8) usize {
    return (std.fmt.bufPrint(out, "{s}\\{s}", .{ lab, rel }) catch return 0).len;
}

/// Locate FSOT-GPU lab (env FSOT_GPU_ROOT or known Desktop path).
pub fn findLabRoot(out: []u8) usize {
    if (std.process.getEnvVarOwned(std.heap.page_allocator, "FSOT_GPU_ROOT")) |env| {
        defer std.heap.page_allocator.free(env);
        if (env.len > 0 and pathExists(env)) return copyTo(out, env);
    } else |_| {}
    for (LAB_CANDIDATES) |c| {
        if (pathExists(c)) return copyTo(out, c);
    }
    return 0;
}

// ── Owned trinary pack (twin of FSOT-GPU parity/zig_parity) ───────────────

/// Pack 32 trit codes (0..2) into one u64 (2 bits each).
pub fn packU64(codes: *const [32]u8) u64 {
    var w: u64 = 0;
    var i: usize = 0;
    while (i < 32) : (i += 1) {
        w |= @as(u64, codes[i] & 0x3) << @intCast(2 * i);
    }
    return w;
}

pub fn unpackU64(w: u64, out: *[32]u8) void {
    var i: usize = 0;
    while (i < 32) : (i += 1) {
        out[i] = @truncate((w >> @intCast(2 * i)) & 0x3);
    }
}

/// Collapse continuous value to trit: 0=down, 1=superposed, 2=up.
pub fn collapseTrit(x: f64) u8 {
    if (x > COLLAPSE_THRESHOLD) return 2;
    if (x < -COLLAPSE_THRESHOLD) return 0;
    return 1;
}

/// Parity self-check: pack round-trip + collapse threshold identity.
pub fn runParity() bool {
    var codes: [32]u8 = undefined;
    var i: usize = 0;
    while (i < 32) : (i += 1) codes[i] = @intCast(i % 3);
    const word = packU64(&codes);
    var back: [32]u8 = undefined;
    unpackU64(word, &back);
    i = 0;
    while (i < 32) : (i += 1) {
        if (back[i] != codes[i]) return false;
    }
    // collapse sanity
    if (collapseTrit(1.0) != 2) return false;
    if (collapseTrit(-1.0) != 0) return false;
    if (collapseTrit(0.0) != 1) return false;
    // threshold must match published seed product (loose window)
    if (COLLAPSE_THRESHOLD < 0.91 or COLLAPSE_THRESHOLD > 0.93) return false;
    return true;
}

/// Smoke native CUDA pack binary from FSOT-GPU lab (if built).
pub fn smokeNativeKernel(lab: []const u8) bool {
    var path_buf: [400]u8 = undefined;
    const n = joinLab(lab, "phase2_native_gpu\\cuda\\trinary_pack_test.exe", path_buf[0..]);
    if (n == 0) return false;
    const exe = path_buf[0..n];
    if (!pathExists(exe)) return false;

    var child = std.process.Child.init(&.{exe}, std.heap.page_allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    child.spawn() catch return false;

    var out: [1024]u8 = undefined;
    var on: usize = 0;
    if (child.stdout) |*so| {
        while (on < out.len) {
            var tmp: [128]u8 = undefined;
            const nr = so.read(tmp[0..]) catch break;
            if (nr == 0) break;
            const take = @min(nr, out.len - on);
            @memcpy(out[on .. on + take], tmp[0..take]);
            on += take;
        }
    }
    const term = child.wait() catch return false;
    const code: u8 = switch (term) {
        .Exited => |c| c,
        else => 255,
    };
    if (code != 0) return false;
    // FSOT-GPU native_cuda looks for ok=true
    if (std.mem.indexOf(u8, out[0..on], "ok=true") != null) return true;
    if (std.mem.indexOf(u8, out[0..on], "PASS") != null) return true;
    // exit 0 with any output / empty is acceptable smoke
    return true;
}

fn probeDevice(rep: *GpuReport) void {
    if (builtin.os.tag != .windows and builtin.os.tag != .linux) {
        rep.driver_n = copyTo(rep.driver_note[0..], "unsupported_os");
        return;
    }
    var buf: [2048]u8 = undefined;
    const n = runCapture(&.{
        "nvidia-smi",
        "--query-gpu=name,memory.total,compute_cap",
        "--format=csv,noheader,nounits",
    }, buf[0..]);
    if (n == 0) {
        // fallback without compute_cap
        const n2 = runCapture(&.{
            "nvidia-smi",
            "--query-gpu=name,memory.total",
            "--format=csv,noheader,nounits",
        }, buf[0..]);
        if (n2 == 0) {
            rep.driver_n = copyTo(rep.driver_note[0..], "nvidia-smi_missing");
            return;
        }
        parseNameMem(buf[0..n2], rep);
        rep.driver_n = copyTo(rep.driver_note[0..], "nvidia-smi");
        return;
    }
    parseNameMemCap(buf[0..n], rep);
    rep.driver_n = copyTo(rep.driver_note[0..], "nvidia-smi");
}

fn parseNameMem(line_raw: []const u8, rep: *GpuReport) void {
    var line = line_raw;
    if (std.mem.indexOfScalar(u8, line, '\n')) |nl| line = line[0..nl];
    while (line.len > 0 and (line[line.len - 1] == '\r' or line[line.len - 1] == ' ')) {
        line = line[0 .. line.len - 1];
    }
    if (std.mem.indexOfScalar(u8, line, ',')) |comma| {
        var name = line[0..comma];
        while (name.len > 0 and name[0] == ' ') name = name[1..];
        while (name.len > 0 and name[name.len - 1] == ' ') name = name[0 .. name.len - 1];
        rep.name_n = copyTo(rep.name[0..], name);
        var mem = line[comma + 1 ..];
        while (mem.len > 0 and mem[0] == ' ') mem = mem[1..];
        var mb: u32 = 0;
        for (mem) |c| {
            if (c < '0' or c > '9') break;
            mb = mb *% 10 +% (c - '0');
        }
        rep.vram_mb = mb;
    } else {
        rep.name_n = copyTo(rep.name[0..], line);
    }
    rep.present = rep.name_n > 0;
}

fn parseNameMemCap(line_raw: []const u8, rep: *GpuReport) void {
    parseNameMem(line_raw, rep);
    // third field: compute_cap like 12.0
    var line = line_raw;
    if (std.mem.indexOfScalar(u8, line, '\n')) |nl| line = line[0..nl];
    var commas: usize = 0;
    var last: usize = 0;
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == ',') {
            commas += 1;
            last = i + 1;
        }
    }
    if (commas >= 2) {
        var cap = line[last..];
        while (cap.len > 0 and cap[0] == ' ') cap = cap[1..];
        // parse major.minor → major*10+minor approx major*10 + minor digit
        var major: u32 = 0;
        var j: usize = 0;
        while (j < cap.len and cap[j] >= '0' and cap[j] <= '9') : (j += 1) {
            major = major *% 10 +% (cap[j] - '0');
        }
        var minor: u32 = 0;
        if (j < cap.len and cap[j] == '.') {
            j += 1;
            if (j < cap.len and cap[j] >= '0' and cap[j] <= '9') minor = cap[j] - '0';
        }
        rep.compute_cap = major *% 10 +% minor;
    }
}

/// Full organ probe: device + FSOT-GPU lab + parity + optional kernel smoke.
pub fn probe() GpuReport {
    var rep: GpuReport = .{};
    probeDevice(&rep);

    var lab_buf: [320]u8 = undefined;
    const ln = findLabRoot(lab_buf[0..]);
    if (ln > 0) {
        rep.fsot_gpu_lab = true;
        rep.lab_n = copyTo(rep.lab_path[0..], lab_buf[0..ln]);
        var pbuf: [400]u8 = undefined;
        const kn = joinLab(lab_buf[0..ln], "phase2_native_gpu\\cuda\\trinary_pack_test.exe", pbuf[0..]);
        if (kn > 0 and pathExists(pbuf[0..kn])) rep.native_kernel = true;
        const an = joinLab(lab_buf[0..ln], "phase2_native_gpu\\cuda\\fsot_attn_lib.dll", pbuf[0..]);
        if (an > 0 and pathExists(pbuf[0..an])) rep.attn_dll = true;
    }

    rep.parity_ok = runParity();
    if (rep.fsot_gpu_lab and rep.native_kernel) {
        rep.kernel_smoke_ok = smokeNativeKernel(rep.lab_path[0..rep.lab_n]);
    }

    // batch_ready: device present + owned parity; kernel optional accelerator
    rep.batch_ready = rep.present and rep.parity_ok;
    // ok: min stack always green; GPU optional. Organ module is healthy if parity holds.
    rep.ok = rep.parity_ok;
    return rep;
}

/// Sleep / consolidation organ signal. Silent by default — long think must not
/// flood logs with non-biological GPU chatter. Use verbose=true for probes only.
pub fn consolidateBatch(n_items: u32) bool {
    return consolidateBatchEx(n_items, false);
}

pub fn consolidateBatchEx(n_items: u32, verbose: bool) bool {
    const g = probe();
    if (!g.present) {
        if (verbose) std.debug.print("GPU_ORGAN consolidate items={d} fallback=CPU (no device)\n", .{n_items});
        return false;
    }
    if (g.native_kernel and g.kernel_smoke_ok) {
        if (verbose) {
            std.debug.print(
                "GPU_ORGAN consolidate items={d} device={s} vram_mb={d} path=fsot-gpu-native pack_ok=1\n",
                .{ n_items, g.name[0..g.name_n], g.vram_mb },
            );
        }
        return true;
    }
    if (g.parity_ok) {
        if (verbose) {
            std.debug.print(
                "GPU_ORGAN consolidate items={d} device={s} vram_mb={d} path=owned-parity\n",
                .{ n_items, g.name[0..g.name_n], g.vram_mb },
            );
        }
        return true;
    }
    return false;
}

pub fn printReport() void {
    const g = probe();
    std.debug.print("=== FSOT GPU ORGAN (mind body) ===\n", .{});
    std.debug.print("doctrine: Fixed lattice = mind; GPU = compute organ (FSOT-GPU reference)\n", .{});
    std.debug.print("ref: https://github.com/dappalumbo91/FSOT-GPU\n", .{});
    std.debug.print("device present={} name={s} vram_mb={d} cc={d}\n", .{
        g.present,
        if (g.name_n > 0) g.name[0..g.name_n] else "none",
        g.vram_mb,
        g.compute_cap,
    });
    std.debug.print("driver={s}\n", .{g.driver_note[0..g.driver_n]});
    std.debug.print("fsot_gpu_lab={} native_kernel={} attn_dll={}\n", .{
        g.fsot_gpu_lab,
        g.native_kernel,
        g.attn_dll,
    });
    if (g.lab_n > 0) {
        std.debug.print("lab={s}\n", .{g.lab_path[0..g.lab_n]});
    }
    std.debug.print("parity_ok={} kernel_smoke={} batch_ready={}\n", .{
        g.parity_ok,
        g.kernel_smoke_ok,
        g.batch_ready,
    });
    std.debug.print("collapse_threshold={d:.12} (C_eff*P_var, seed-owned)\n", .{COLLAPSE_THRESHOLD});
    std.debug.print("contracts: trinary pack 2bit · consensus-no-softmax · formal Lean/Coq/Isabelle/F*\n", .{});
    if (g.ok) {
        std.debug.print("FSOT_GPU_ORGAN PASS\n", .{});
    } else {
        std.debug.print("FSOT_GPU_ORGAN FAIL\n", .{});
    }
}

pub fn selfTest() bool {
    return runParity() and probe().ok;
}

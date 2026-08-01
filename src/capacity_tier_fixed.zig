//! Hardware capacity tiers — silicon body growth under FSOT mind authority.
//!
//! Minimum stack (Mac Mini / Pi class) always boots.
//! Omen 32GB + GPU = capacity growth, not a different architecture.
//!
//! Doctrine (STM vs LTM):
//!   - lit_cards / grown_cap = **STM hot-window budgets** (RAM working set)
//!   - Knowledge growth is **unbounded** via disk LTM (`data/ltm/`)
//!   - A full STM window triggers spill-to-disk, never "memory full stop"
//!   - CPU (+ GPU later) = thought compute organs; disk = long-term cortex
//!
//! Mode: fsot_mind capacity

const std = @import("std");
const builtin = @import("builtin");
const ltm = @import("ltm_disk_fixed.zig");
const gpu_organ = @import("gpu_organ_fixed.zig");

pub const Tier = enum(u8) {
    /// Developmental floor — always green without GPU
    min = 0,
    /// Comfortable 16GB-class desktop
    desktop = 1,
    /// 32GB workstation (HP Omen lab)
    workstation = 2,
};

pub const CapConfig = struct {
    tier: Tier = .min,
    /// Detected physical RAM bytes (0 if unknown)
    ram_bytes: u64 = 0,
    ram_gb: u32 = 0,
    /// GPU organ present (driver/tooling) — not mind authority
    gpu_organ: bool = false,
    gpu_note: []const u8 = "none",
    /// Literature cards loaded into STM at think boot
    lit_cards: u32 = 40,
    /// Grown-concept **STM hot window** (not knowledge ceiling — LTM spills beyond this)
    grown_cap: u32 = 256,
    discover_per_pass: u32 = 1,
    utter_depth: u32 = 1, // multi-engram frames later
    sleep_every: u32 = 10,
    /// Disk LTM always available on host mind (unbounded growth organ)
    ltm_disk: bool = true,
    /// Human labels
    body_label: []const u8 = "minimum",
    host_hint: []const u8 = "unknown",
};

fn tierName(t: Tier) []const u8 {
    return switch (t) {
        .min => "min",
        .desktop => "desktop",
        .workstation => "workstation",
    };
}

/// Windows: GetPhysicallyInstalledSystemMemory (KB → bytes).
fn probeRamWindows() u64 {
    if (builtin.os.tag != .windows) return 0;
    const GetPhys = struct {
        extern "kernel32" fn GetPhysicallyInstalledSystemMemory(kb: *u64) callconv(.winapi) std.os.windows.BOOL;
    }.GetPhysicallyInstalledSystemMemory;
    var kb: u64 = 0;
    if (GetPhys(&kb) == 0) return 0;
    return kb *% 1024;
}

/// GPU organ note for capacity print — uses FSOT-GPU bridge (parity + lab).
fn probeGpuOrgan() struct { present: bool, note: []const u8 } {
    const g = gpu_organ.probe();
    if (!g.present) return .{ .present = false, .note = "none" };
    if (g.batch_ready and g.native_kernel) return .{ .present = true, .note = "fsot-gpu+native" };
    if (g.batch_ready and g.fsot_gpu_lab) return .{ .present = true, .note = "fsot-gpu-lab" };
    if (g.parity_ok) return .{ .present = true, .note = "fsot-parity+smi" };
    return .{ .present = true, .note = "nvidia-smi" };
}

fn applyTier(cfg: *CapConfig) void {
    const gb = cfg.ram_gb;
    cfg.ltm_disk = true; // host mind always has disk LTM organ
    if (gb >= 24) {
        cfg.tier = .workstation;
        cfg.body_label = "workstation-growth";
        cfg.lit_cards = 160;
        // Large STM window; beyond this → disk LTM (unbounded knowledge)
        cfg.grown_cap = 1536;
        cfg.discover_per_pass = 2;
        cfg.utter_depth = 2;
        cfg.sleep_every = 8;
        cfg.host_hint = "Omen-class 32GB: fat STM + disk LTM + GPU organ flag";
    } else if (gb >= 12) {
        cfg.tier = .desktop;
        cfg.body_label = "desktop";
        cfg.lit_cards = 80;
        cfg.grown_cap = 768;
        cfg.discover_per_pass = 2;
        cfg.utter_depth = 1;
        cfg.sleep_every = 8;
        cfg.host_hint = "16GB desktop: medium STM + disk LTM";
    } else {
        cfg.tier = .min;
        cfg.body_label = "minimum-stack";
        cfg.lit_cards = 40;
        cfg.grown_cap = 256;
        cfg.discover_per_pass = 1;
        cfg.utter_depth = 1;
        cfg.sleep_every = 10;
        cfg.host_hint = "Mac Mini / Pi class floor: small STM + disk LTM";
    }
    // Unknown RAM: assume workstation on Windows host build (lab Omen), min otherwise
    if (cfg.ram_bytes == 0) {
        if (builtin.os.tag == .windows) {
            cfg.tier = .workstation;
            cfg.body_label = "workstation-assumed";
            cfg.lit_cards = 160;
            cfg.grown_cap = 1536;
            cfg.discover_per_pass = 2;
            cfg.utter_depth = 2;
            cfg.sleep_every = 8;
            cfg.host_hint = "RAM probe failed; assume Omen-class growth host";
        } else {
            cfg.tier = .min;
            cfg.host_hint = "non-windows / unknown RAM → minimum stack";
        }
    }
}

/// Probe host body and return capacity config.
pub fn probe() CapConfig {
    var cfg: CapConfig = .{};
    if (builtin.os.tag == .windows) {
        cfg.ram_bytes = probeRamWindows();
    }
    if (cfg.ram_bytes > 0) {
        cfg.ram_gb = @intCast(@min(cfg.ram_bytes / (1024 * 1024 * 1024), 512));
    }
    const g = probeGpuOrgan();
    cfg.gpu_organ = g.present;
    cfg.gpu_note = g.note;
    applyTier(&cfg);
    return cfg;
}

pub fn printReport(cfg: CapConfig) void {
    std.debug.print("=== FSOT SILICON BODY / CAPACITY ===\n", .{});
    std.debug.print("doctrine: STM=RAM hot window; LTM=disk (unbounded); CPU/GPU=thought organs\n", .{});
    std.debug.print("tier={s} body={s}\n", .{ tierName(cfg.tier), cfg.body_label });
    std.debug.print("ram_gb={d} ram_bytes={d}\n", .{ cfg.ram_gb, cfg.ram_bytes });
    std.debug.print("gpu_organ={} note={s}\n", .{ cfg.gpu_organ, cfg.gpu_note });
    const g = gpu_organ.probe();
    if (g.present) {
        std.debug.print("GPU detail device={s} vram_mb={d} parity={} lab={} batch_ready={}\n", .{
            if (g.name_n > 0) g.name[0..g.name_n] else "?",
            g.vram_mb,
            g.parity_ok,
            g.fsot_gpu_lab,
            g.batch_ready,
        });
    }
    std.debug.print("STM budgets lit_cards={d} stm_grown={d} discover/pass={d} utter_depth={d} sleep_every={d}\n", .{
        cfg.lit_cards,
        cfg.grown_cap,
        cfg.discover_per_pass,
        cfg.utter_depth,
        cfg.sleep_every,
    });
    std.debug.print("LTM disk={} path={s} (knowledge ceiling=none — spill when STM full)\n", .{
        cfg.ltm_disk,
        ltm.LTM_DIR,
    });
    const tot = ltm.reportLtmTotals();
    std.debug.print("LTM lines grown={d} engrams={d} episodes={d}\n", .{ tot.grown, tot.engrams, tot.episodes });
    std.debug.print("host_hint={s}\n", .{cfg.host_hint});
    std.debug.print("paths: QEMU sim on growth host → flash image → Mac Mini body\n", .{});
    std.debug.print("GPU ref: github.com/dappalumbo91/FSOT-GPU · mode gpu-organ\n", .{});
    std.debug.print("--- operating envelope (see docs/OPERATING_SPECS.md) ---\n", .{});
    std.debug.print("floor_host: >=4GB RAM, x86_64/aarch64, no GPU required\n", .{});
    std.debug.print("qemu_kernel: Multiboot x86, -m 64M class, serial console\n", .{});
    std.debug.print("host_modes_floor: bio-learn, speech, think-probe, capacity, genetic-var\n", .{});
    std.debug.print("host_modes_heavy: think-hour, fixed+allen-dist, intel-loop, gpu-organ\n", .{});
    std.debug.print("docs: docs/MINIMUM_STACK.md · docs/OPERATING_SPECS.md · docs/SILICON_BODY_ARCHITECTURE.md\n", .{});
    std.debug.print("FSOT_CAPACITY_OK\n", .{});
}

pub fn selfTest() bool {
    const c = probe();
    if (!(c.lit_cards >= 40 and c.grown_cap >= 64 and c.ltm_disk)) return false;
    return ltm.selfTest();
}

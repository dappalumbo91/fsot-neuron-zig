//! Hardware capacity tiers — silicon body growth under FSOT mind authority.
//!
//! Minimum stack (Mac Mini / Pi class) always boots.
//! Omen 32GB + GPU = capacity growth, not a different architecture.
//!
//! Mode: fsot_mind capacity

const std = @import("std");
const builtin = @import("builtin");

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
    /// Think / literature budgets (runtime)
    lit_cards: u32 = 40,
    grown_cap: u32 = 64,
    discover_per_pass: u32 = 1,
    utter_depth: u32 = 1, // multi-engram frames later
    sleep_every: u32 = 10,
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

fn probeGpuOrgan() struct { present: bool, note: []const u8 } {
    if (builtin.os.tag != .windows) return .{ .present = false, .note = "n/a" };
    // Lightweight: if nvidia-smi exists, GPU organ available
    var child = std.process.Child.init(&.{ "where", "nvidia-smi" }, std.heap.page_allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;
    const r = child.spawnAndWait() catch return .{ .present = false, .note = "none" };
    return switch (r) {
        .Exited => |code| if (code == 0) .{ .present = true, .note = "nvidia-smi" } else .{ .present = false, .note = "none" },
        else => .{ .present = false, .note = "none" },
    };
}

fn applyTier(cfg: *CapConfig) void {
    const gb = cfg.ram_gb;
    if (gb >= 24) {
        cfg.tier = .workstation;
        cfg.body_label = "workstation-growth";
        cfg.lit_cards = 160;
        cfg.grown_cap = 256;
        cfg.discover_per_pass = 2;
        cfg.utter_depth = 2;
        cfg.sleep_every = 8;
        cfg.host_hint = "Omen-class 32GB (or similar)";
    } else if (gb >= 12) {
        cfg.tier = .desktop;
        cfg.body_label = "desktop";
        cfg.lit_cards = 80;
        cfg.grown_cap = 128;
        cfg.discover_per_pass = 2;
        cfg.utter_depth = 1;
        cfg.sleep_every = 8;
        cfg.host_hint = "16GB desktop";
    } else {
        cfg.tier = .min;
        cfg.body_label = "minimum-stack";
        cfg.lit_cards = 40;
        cfg.grown_cap = 64;
        cfg.discover_per_pass = 1;
        cfg.utter_depth = 1;
        cfg.sleep_every = 10;
        cfg.host_hint = "Mac Mini / Pi class floor";
    }
    // Unknown RAM: assume workstation on Windows host build (lab Omen), min otherwise
    if (cfg.ram_bytes == 0) {
        if (builtin.os.tag == .windows) {
            cfg.tier = .workstation;
            cfg.body_label = "workstation-assumed";
            cfg.lit_cards = 160;
            cfg.grown_cap = 256;
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
    std.debug.print("doctrine: min stack boots always; Omen/GPU = growth organs under Fixed mind\n", .{});
    std.debug.print("tier={s} body={s}\n", .{ tierName(cfg.tier), cfg.body_label });
    std.debug.print("ram_gb={d} ram_bytes={d}\n", .{ cfg.ram_gb, cfg.ram_bytes });
    std.debug.print("gpu_organ={} note={s}\n", .{ cfg.gpu_organ, cfg.gpu_note });
    std.debug.print("budgets lit_cards={d} grown_cap={d} discover/pass={d} utter_depth={d} sleep_every={d}\n", .{
        cfg.lit_cards,
        cfg.grown_cap,
        cfg.discover_per_pass,
        cfg.utter_depth,
        cfg.sleep_every,
    });
    std.debug.print("host_hint={s}\n", .{cfg.host_hint});
    std.debug.print("paths: QEMU sim on growth host → flash image → Mac Mini body\n", .{});
    std.debug.print("docs: docs/MINIMUM_STACK.md · docs/SILICON_BODY_ARCHITECTURE.md\n", .{});
    std.debug.print("FSOT_CAPACITY_OK\n", .{});
}

pub fn selfTest() bool {
    const c = probe();
    return c.lit_cards >= 40 and c.grown_cap >= 64;
}

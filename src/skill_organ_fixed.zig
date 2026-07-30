//! Python skill organ — interpreter sandbox for procedural skills.
//!
//! Doctrine:
//!   - Fixed mind stays authority (Zig lattice / genetics).
//!   - Python is a **body organ** for executable skills (like hands + tools),
//!     not a second brain / LLM.
//!   - Skills live under skills/python/skills/; runner enforces timeout.
//!   - Result text can bind as SpeakEngram / grown knowledge (experience).
//!
//! Mode: fsot_mind skill | skill-probe
//! Later: Rust compiled skills can share the same organ interface.

const std = @import("std");
const fixed = @import("fixed.zig");
const memory_f = @import("memory_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const Fixed = fixed.Fixed;

pub const SKILLS_DIR = "skills/python";
pub const RUNNER = "skills/python/runner.py";
pub const DEFAULT_TIMEOUT_MS: u32 = 8_000;

pub const SkillResult = struct {
    ok: bool = false,
    skill: [48]u8 = .{0} ** 48,
    skill_n: usize = 0,
    stdout: [512]u8 = .{0} ** 512,
    stdout_n: usize = 0,
    stderr_n: usize = 0,
    exit_code: i32 = -1,
    duration_ms: u64 = 0,
    python_path: [260]u8 = .{0} ** 260,
    python_n: usize = 0,
};

fn copyTo(dst: []u8, src: []const u8) usize {
    const n = @min(src.len, dst.len);
    @memcpy(dst[0..n], src[0..n]);
    return n;
}

/// Prefer system Python over hermes venv when possible.
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

/// Run a named skill via skills/python/runner.py.
/// `skill` is the module name without .py (e.g. "add").
/// `arg` optional single argument string (may be empty).
pub fn runSkill(skill: []const u8, arg: []const u8, timeout_ms: u32) SkillResult {
    var res: SkillResult = .{};
    res.skill_n = copyTo(res.skill[0..], skill);

    var pybuf: [260]u8 = undefined;
    const pn = resolvePython(pybuf[0..]);
    if (pn == 0) {
        res.stdout_n = copyTo(res.stdout[0..], "ERROR: no python interpreter");
        return res;
    }
    res.python_n = copyTo(res.python_path[0..], pybuf[0..pn]);

    // Ensure runner exists
    std.fs.cwd().access(RUNNER, .{}) catch {
        res.stdout_n = copyTo(res.stdout[0..], "ERROR: missing skills/python/runner.py");
        return res;
    };

    const t0 = std.time.milliTimestamp();
    var argv_buf: [6][]const u8 = undefined;
    var argc: usize = 0;
    argv_buf[argc] = pybuf[0..pn];
    argc += 1;
    argv_buf[argc] = RUNNER;
    argc += 1;
    argv_buf[argc] = skill;
    argc += 1;
    if (arg.len > 0) {
        argv_buf[argc] = arg;
        argc += 1;
    }

    var child = std.process.Child.init(argv_buf[0..argc], std.heap.page_allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    child.spawn() catch {
        res.stdout_n = copyTo(res.stdout[0..], "ERROR: spawn failed");
        return res;
    };

    // Read stdout with simple deadline
    var out_acc: [512]u8 = undefined;
    var out_n: usize = 0;
    var err_acc: [256]u8 = undefined;
    var err_n: usize = 0;

    const deadline = t0 + @as(i64, @intCast(if (timeout_ms == 0) DEFAULT_TIMEOUT_MS else timeout_ms));
    if (child.stdout) |*so| {
        while (out_n < out_acc.len) {
            if (std.time.milliTimestamp() > deadline) break;
            var tmp: [128]u8 = undefined;
            const nr = so.read(tmp[0..]) catch break;
            if (nr == 0) break;
            const take = @min(nr, out_acc.len - out_n);
            @memcpy(out_acc[out_n .. out_n + take], tmp[0..take]);
            out_n += take;
        }
    }
    if (child.stderr) |*se| {
        while (err_n < err_acc.len) {
            if (std.time.milliTimestamp() > deadline) break;
            var tmp: [64]u8 = undefined;
            const nr = se.read(tmp[0..]) catch break;
            if (nr == 0) break;
            const take = @min(nr, err_acc.len - err_n);
            @memcpy(err_acc[err_n .. err_n + take], tmp[0..take]);
            err_n += take;
        }
    }

    // If past deadline, kill
    if (std.time.milliTimestamp() > deadline) {
        _ = child.kill() catch {};
    }
    const term = child.wait() catch {
        res.stdout_n = copyTo(res.stdout[0..], "ERROR: wait failed");
        return res;
    };
    res.exit_code = switch (term) {
        .Exited => |c| @intCast(c),
        else => -1,
    };
    const t1 = std.time.milliTimestamp();
    res.duration_ms = if (t1 >= t0) @intCast(t1 - t0) else 0;

    // Prefer RESULT: line from stdout
    var line_start: usize = 0;
    var i: usize = 0;
    var got_result = false;
    while (i <= out_n) : (i += 1) {
        if (i == out_n or out_acc[i] == '\n') {
            const line = out_acc[line_start..i];
            if (line.len >= 7 and std.mem.startsWith(u8, line, "RESULT:")) {
                var body = line[7..];
                while (body.len > 0 and body[0] == ' ') body = body[1..];
                res.stdout_n = copyTo(res.stdout[0..], body);
                got_result = true;
                break;
            }
            line_start = i + 1;
        }
    }
    if (!got_result) {
        // trim trailing newlines from raw stdout
        var end = out_n;
        while (end > 0 and (out_acc[end - 1] == '\n' or out_acc[end - 1] == '\r')) end -= 1;
        res.stdout_n = copyTo(res.stdout[0..], out_acc[0..end]);
    }
    res.stderr_n = err_n;
    res.ok = res.exit_code == 0 and res.stdout_n > 0 and !std.mem.startsWith(u8, res.stdout[0..res.stdout_n], "ERROR:");
    return res;
}

/// Bind skill output into organism as motor engram + episode (experience learning).
pub fn bindSkillResult(org: *organism_f.OrganismF, skill: []const u8, result: *const SkillResult) bool {
    if (!result.ok or result.stdout_n == 0) return false;
    var feats: [8]Fixed = .{0} ** 8;
    const h = memory_f.hashToken(skill);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        feats[i] = fixed.div(fixed.fromInt(@intCast((h >> @intCast(i * 3)) & 7)), fixed.fromInt(8));
    }
    const toks = [_]u32{
        memory_f.hashToken("skill"),
        memory_f.hashToken(skill),
        memory_f.hashToken(result.stdout[0..@min(result.stdout_n, 24)]),
        0,
        0,
        memory_f.hashToken("python"),
    };
    const ep = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    var phrase: [96]u8 = undefined;
    const pn = (std.fmt.bufPrint(phrase[0..], "skill {s}: {s}", .{
        skill[0..@min(skill.len, 20)],
        result.stdout[0..@min(result.stdout_n, 60)],
    }) catch "skill").len;
    org.bindSpeakEngram(ep, skill, result.stdout[0..result.stdout_n], phrase[0..pn], feats[0..]);
    org.setMeaning(feats[0..]);
    org.speakNow();
    return true;
}

pub const SkillProbeReport = struct {
    ok: bool = false,
    n_skills: u32 = 0,
    n_ok: u32 = 0,
    python_found: bool = false,
};

/// Run built-in probe skills: add, reverse.
pub fn runProbe() SkillProbeReport {
    var rep: SkillProbeReport = .{};
    var py: [260]u8 = undefined;
    rep.python_found = resolvePython(py[0..]) > 0;
    if (!rep.python_found) return rep;

    const tests = [_]struct { name: []const u8, arg: []const u8, expect_sub: []const u8 }{
        .{ .name = "add", .arg = "2 3", .expect_sub = "5" },
        .{ .name = "reverse", .arg = "abc", .expect_sub = "cba" },
        .{ .name = "mul", .arg = "4 5", .expect_sub = "20" },
        .{ .name = "div", .arg = "10 2", .expect_sub = "5" },
        .{ .name = "gcd", .arg = "12 18", .expect_sub = "6" },
        .{ .name = "sort_words", .arg = "dog cat ant", .expect_sub = "ant" },
        .{ .name = "upper", .arg = "mind", .expect_sub = "MIND" },
        .{ .name = "hash_fnv", .arg = "fsot", .expect_sub = "" }, // any nonzero digits
        .{ .name = "gpu_topk", .arg = "3 2 | 1 0 | 0 1 | 1 0.1", .expect_sub = "0 2" },
    };
    for (tests) |t| {
        rep.n_skills += 1;
        const r = runSkill(t.name, t.arg, DEFAULT_TIMEOUT_MS);
        const match = if (t.expect_sub.len == 0)
            r.ok and r.stdout_n > 0
        else
            r.ok and std.mem.indexOf(u8, r.stdout[0..r.stdout_n], t.expect_sub) != null;
        if (match) {
            rep.n_ok += 1;
        } else {
            std.debug.print("SKILL_FAIL {s} exit={d} out={s}\n", .{
                t.name,
                r.exit_code,
                r.stdout[0..r.stdout_n],
            });
        }
    }
    // Bind one result into a fresh organism as experience smoke
    if (rep.n_ok > 0) {
        var org = organism_f.OrganismF.init();
        const r = runSkill("add", "10 7", DEFAULT_TIMEOUT_MS);
        if (r.ok) _ = bindSkillResult(&org, "add", &r);
        rep.ok = rep.n_ok == rep.n_skills and org.n_speak_engrams >= 1;
    }
    return rep;
}

pub fn selfTest() bool {
    return runProbe().ok;
}

pub fn printProbe() void {
    std.debug.print("=== FSOT PYTHON SKILL ORGAN ===\n", .{});
    std.debug.print("doctrine: Python = skill organ (interpreter), not mind authority\n", .{});
    std.debug.print("runner={s} skills_dir={s}/skills\n", .{ RUNNER, SKILLS_DIR });
    const r = runProbe();
    std.debug.print("python_found={} skills={d}/{d} ok={}\n", .{ r.python_found, r.n_ok, r.n_skills, r.ok });
    if (r.ok) {
        std.debug.print("FSOT_SKILL_ORGAN PASS\n", .{});
    } else {
        std.debug.print("FSOT_SKILL_ORGAN FAIL\n", .{});
    }
}

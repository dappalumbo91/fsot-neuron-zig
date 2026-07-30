//! Know-or-query learning — human "I don't know → look it up → keep it".
//!
//! Process (bio, not chat LLM):
//!   1) Probe concept via retrieve/engram
//!   2) If miss: admit unknown → query_tool (archive/wiki/API curriculum)
//!   3) Experience definition → encode episode + SpeakEngram (retain)
//!   4) Re-probe: must now hit from memory
//!
//! Mode: fsot_mind know-query | study-tool | lookup-learn

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const query_tool = @import("query_tool_fixed.zig");
const Fixed = fixed.Fixed;

/// Concepts to probe — mix of known seeds and "should look up" words.
const PROBES = [_][]const u8{
    "table",
    "chair",
    "neuron",
    "gravity",
    "water",
    "sun",
    "photosynthesis",
    "mitochondria",
    "black hole",
    "quantum",
    "democracy",
    "pyramid",
    "oxygen",
    "enzyme",
    "telescope",
};

fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    const base = memory_f.hashToken(cue);
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const mix = base *% (@as(u32, @intCast(i)) +% 1) *% 0x9E3779B1 +% 71;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(mix % 181)), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

fn drive(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState, feats: *const [8]Fixed, steps: usize) void {
    var ext: [brain_f.N_TOTAL]Fixed = undefined;
    var t: usize = 0;
    while (t < steps) : (t += 1) {
        neuromod_f.step(nm, .wake_encode, 0, fixed.fromDecimalStr("0.05"), fixed.fromDecimalStr("0.03"), 0, fixed.fromInt(1));
        const g = neuromod_f.encodeGain(nm);
        var i: usize = 0;
        while (i < org.brain.n) : (i += 1) {
            const f = feats[i % 8];
            ext[i] = fixed.clamp(fixed.mul(fixed.mul(fixed.fromDecimalStr("0.62"), f), g), fixed.fromDecimalStr("-0.5"), fixed.fromDecimalStr("1.5"));
        }
        org.brain.step(ext[0..]);
    }
}

fn recall(org: *organism_f.OrganismF, cue: []const u8) bool {
    // known if engram exists for cue
    if (org.engramForCue(memory_f.hashToken(cue))) |_| return true;
    var feats: [8]Fixed = undefined;
    cueFeat(cue, &feats);
    var sim: Fixed = 0;
    const ep = org.store.retrieve(&org.brain, feats[0..], &sim);
    if (ep == 0) return false;
    if (org.store.findEpisode(ep)) |e| {
        return e.tokens[2] == memory_f.hashToken(cue);
    }
    return false;
}

/// Study a definition into organism (experience → engram).
fn retainDefinition(
    org: *organism_f.OrganismF,
    nm: *neuromod_f.NeuromodState,
    term: []const u8,
    def: []const u8,
) void {
    var feats: [8]Fixed = undefined;
    cueFeat(term, &feats);
    var ans_f: [8]Fixed = undefined;
    cueFeat(def, &ans_f);
    var meaning: [8]Fixed = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        meaning[i] = fixed.add(
            fixed.mul(feats[i], fixed.fromDecimalStr("0.45")),
            fixed.mul(ans_f[i], fixed.fromDecimalStr("0.55")),
        );
    }
    drive(org, nm, &feats, 12);
    // answer token = first word of definition for hash stability
    var first: []const u8 = def;
    if (std.mem.indexOfScalar(u8, def, ' ')) |sp| first = def[0..sp];
    const toks = [_]u32{
        memory_f.hashToken("learn"),
        memory_f.hashToken(first),
        memory_f.hashToken(term),
        memory_f.hashToken(term),
        memory_f.hashToken("query"),
        memory_f.hashToken("tool"),
    };
    const ep = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
    // utterable: "term: definition"
    var utter: [180]u8 = undefined;
    const u = std.fmt.bufPrint(utter[0..], "{s}: {s}", .{ term, def }) catch term;
    org.bindSpeakEngram(ep, term, first, u, meaning[0..]);
    org.setMeaning(meaning[0..]);
    org.speakNow();
    neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.14"));
}

pub const KnowQueryReport = struct {
    ok: bool = false,
    n_probes: u32 = 0,
    n_already_known: u32 = 0,
    n_unknown: u32 = 0,
    n_queried: u32 = 0,
    n_query_hit: u32 = 0,
    n_query_miss: u32 = 0,
    n_retained: u32 = 0,
    n_reprobe_ok: u32 = 0,
    n_said_unknown: u32 = 0,
    allow_live: bool = false,
    last_term: [32]u8 = .{0} ** 32,
    last_term_n: usize = 0,
    last_def: [160]u8 = .{0} ** 160,
    last_def_n: usize = 0,
    last_via: [48]u8 = .{0} ** 48,
    last_via_n: usize = 0,
    n_engrams: u32 = 0,
    n_episodes: u32 = 0,
};

/// Run know-or-query curriculum.
pub fn runKnowQuery(allow_live: bool) KnowQueryReport {
    var rep: KnowQueryReport = .{ .allow_live = allow_live };
    var org = organism_f.OrganismF.init();
    org.encode_every = 0;
    org.steps_per_tick = 3;
    var nm: neuromod_f.NeuromodState = .{};

    // optional seed: learn "water" without query so some are already known
    retainDefinition(&org, &nm, "water", "clear liquid that living things drink");
    retainDefinition(&org, &nm, "sun", "the star that lights the day");

    for (PROBES) |term| {
        rep.n_probes += 1;
        rep.last_term_n = @min(term.len, rep.last_term.len);
        @memcpy(rep.last_term[0..rep.last_term_n], term[0..rep.last_term_n]);

        // 1) Do I already know this?
        if (recall(&org, term)) {
            rep.n_already_known += 1;
            continue;
        }

        // 2) Admit unknown (human metacognition)
        rep.n_unknown += 1;
        rep.n_said_unknown += 1;
        // encode "I don't know TERM" moment (curiosity open)
        var ufeats: [8]Fixed = undefined;
        cueFeat(term, &ufeats);
        const utoks = [_]u32{
            memory_f.hashToken("self"),
            memory_f.hashToken("unknown"),
            memory_f.hashToken(term),
            0,
            0,
            memory_f.hashToken("ask"),
        };
        _ = org.store.encode(&org.brain, ufeats[0..], 0b000111, utoks);

        // 3) Query tool (archive / wiki / optional live API)
        rep.n_queried += 1;
        const hit = query_tool.queryConcept(term, allow_live);
        if (!hit.found) {
            rep.n_query_miss += 1;
            // Tuck away for later clarification (same safety as think pending log)
            std.fs.cwd().makePath("data/results") catch {};
            if (std.fs.cwd().openFile("data/results/THINK_PENDING_QUESTIONS.jsonl", .{ .mode = .write_only })) |pf| {
                defer pf.close();
                pf.seekFromEnd(0) catch {};
                var line: [200]u8 = undefined;
                if (std.fmt.bufPrint(line[0..], "{{\"status\":\"open\",\"question\":\"what is {s}?\",\"reason\":\"query_miss\",\"via\":\"know-query\"}}\n", .{term})) |out| {
                    pf.writeAll(out) catch {};
                } else |_| {}
            } else |_| {
                if (std.fs.cwd().createFile("data/results/THINK_PENDING_QUESTIONS.jsonl", .{})) |pf| {
                    defer pf.close();
                    var line: [200]u8 = undefined;
                    if (std.fmt.bufPrint(line[0..], "{{\"status\":\"open\",\"question\":\"what is {s}?\",\"reason\":\"query_miss\",\"via\":\"know-query\"}}\n", .{term})) |out| {
                        pf.writeAll(out) catch {};
                    } else |_| {}
                } else |_| {}
            }
            continue;
        }
        rep.n_query_hit += 1;
        rep.last_def_n = hit.def_n;
        @memcpy(rep.last_def[0..hit.def_n], hit.def[0..hit.def_n]);
        rep.last_via_n = hit.source_n;
        @memcpy(rep.last_via[0..hit.source_n], hit.source[0..hit.source_n]);

        // 4) Retain like a human studying the answer
        retainDefinition(&org, &nm, term, hit.def[0..hit.def_n]);
        rep.n_retained += 1;

        // 5) Re-probe from memory only
        if (recall(&org, term)) {
            rep.n_reprobe_ok += 1;
        }
    }

    rep.n_engrams = @intCast(org.n_speak_engrams);
    rep.n_episodes = @intCast(org.store.n);

    // Pass: unknowns were queried, hits retained, re-probe mostly works
    rep.ok = rep.n_probes >= 8 and
        rep.n_queried >= 3 and
        rep.n_query_hit >= 2 and
        rep.n_retained >= 2 and
        rep.n_reprobe_ok >= (rep.n_retained * 3 / 4) and
        rep.n_said_unknown >= 1;

    return rep;
}

pub fn selfTest() bool {
    if (!query_tool.selfTest()) return false;
    const r = runKnowQuery(false);
    return r.ok;
}

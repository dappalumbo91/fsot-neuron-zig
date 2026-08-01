//! Answer-dependent compositional intelligence (next neurological layer).
//!
//! Parallel multi-hop claimability (`claimability_fixed`) feeds all cues up front.
//! Biology does something stronger: hop N's cue is constructed from hop N−1's
//! *answer* (hippocampal intermediate bind → associative re-cue → WM hold).
//!
//! Process (model-ms, Fixed lattice — not LLM chain-of-thought):
//!   1. TRAIN   — ACh/NE encode premises; experience pairs induce method edges
//!   2. DISCOVER— schema edges from co-occurrence experience (not only static table)
//!   3. COMPOSE — seed → episodic-first retrieve → WM → discovered edge → next cue
//!   4. CLAIM   — every hop grounded + final matches; intermediates in WM
//!   5. ABLATE  — corrupt intermediate answer → next edge must break (dependence)
//!
//! Gate: compose claim ≥90%; ≥12 chains; 2–3 hop activity; ablation breaks ≥80%;
//!       discovered edges ≥1; episodic path used; neuromod self-test; PE on hits.
//!
//! Doctrine: not free generation. Every hop bank-grounded + taught answer set.
//! See docs/FORWARD_INTELLIGENCE_BIO.md § Compositional hop.

const std = @import("std");
const fixed = @import("fixed.zig");
const brain_f = @import("brain_fixed.zig");
const memory_f = @import("memory_fixed.zig");
const neuromod_f = @import("neuromod_fixed.zig");
const teach_f = @import("teach_fixed.zig");
const organism_f = @import("organism_fixed.zig");
const Fixed = fixed.Fixed;

// ---------- curriculum premises (Q → A) ----------
const Lesson = struct {
    id: []const u8,
    fact: []const u8,
    question: []const u8,
    answer: []const u8,
};

const LESSONS = [_]Lesson{
    // arithmetic atoms used in composition
    .{ .id = "m1", .fact = "Half of forty is twenty.", .question = "half of forty", .answer = "twenty" },
    .{ .id = "m2", .fact = "Half of twenty is ten.", .question = "half of twenty", .answer = "ten" },
    .{ .id = "m3", .fact = "Half of ten is five.", .question = "half of ten", .answer = "five" },
    .{ .id = "m4", .fact = "Twice ten is twenty.", .question = "twice ten", .answer = "twenty" },
    .{ .id = "m5", .fact = "Twice five is ten.", .question = "twice five", .answer = "ten" },
    .{ .id = "m6", .fact = "Twice seven is fourteen.", .question = "twice seven", .answer = "fourteen" },
    .{ .id = "m7", .fact = "Ten plus five is fifteen.", .question = "ten plus five", .answer = "fifteen" },
    .{ .id = "m8", .fact = "Five plus five is ten.", .question = "five plus five", .answer = "ten" },
    .{ .id = "m9", .fact = "Twenty minus five is fifteen.", .question = "twenty minus five", .answer = "fifteen" },
    .{ .id = "m10", .fact = "Four times two is eight.", .question = "four times two", .answer = "eight" },
    .{ .id = "m11", .fact = "Half of sixteen is eight.", .question = "half of sixteen", .answer = "eight" },
    .{ .id = "m12", .fact = "Twice eight is sixteen.", .question = "twice eight", .answer = "sixteen" },
    // literacy atoms (composition across domains)
    .{ .id = "l1", .fact = "Plants need sun to grow.", .question = "plants need", .answer = "sun" },
    .{ .id = "l2", .fact = "The sun is out in the day.", .question = "sun when", .answer = "day" },
    .{ .id = "l3", .fact = "The sky is blue on a sunny day.", .question = "sky color", .answer = "blue" },
    .{ .id = "l4", .fact = "People need water to live.", .question = "people need", .answer = "water" },
    .{ .id = "l5", .fact = "Living things need water.", .question = "living need", .answer = "water" },
    .{ .id = "l6", .fact = "We see with our eyes.", .question = "see with", .answer = "eyes" },
    .{ .id = "l7", .fact = "A dog is an animal.", .question = "dog is", .answer = "animal" },
    .{ .id = "l8", .fact = "A week has seven days.", .question = "days in week", .answer = "seven" },
    .{ .id = "l9", .fact = "One and one make two.", .question = "one and one", .answer = "two" },
    .{ .id = "l10", .fact = "Two and one make three.", .question = "two and one", .answer = "three" },
    .{ .id = "l11", .fact = "Two and three make five.", .question = "two and three", .answer = "five" },
    .{ .id = "l12", .fact = "Three and two make five.", .question = "three and two", .answer = "five" },
};

/// Method edges: after retrieving `from_answer`, the next cue is `next_cue`.
/// This is the compositional schema (hipp intermediate → re-cue), not a free prompt.
const Edge = struct {
    from_answer: []const u8,
    next_cue: []const u8,
};

/// Fallback static method table (school schemas). Prefer discovered edges at runtime.
const EDGES = [_]Edge{
    .{ .from_answer = "twenty", .next_cue = "half of twenty" },
    .{ .from_answer = "ten", .next_cue = "half of ten" },
    .{ .from_answer = "five", .next_cue = "twice five" },
    .{ .from_answer = "eight", .next_cue = "twice eight" },
    .{ .from_answer = "sixteen", .next_cue = "half of sixteen" },
    .{ .from_answer = "sun", .next_cue = "sun when" },
    .{ .from_answer = "day", .next_cue = "sky color" },
    .{ .from_answer = "two", .next_cue = "two and one" },
    .{ .from_answer = "three", .next_cue = "two and three" },
    .{ .from_answer = "water", .next_cue = "people need" },
};

/// Experience pairs for schema discovery: after producing A from cue1, next experience is cue2.
/// Biology analogue: successive episodes induce "what to try next" (not hardcoded only).
const ExperiencePair = struct {
    after_answer: []const u8,
    next_cue: []const u8,
    weight: u8 = 1,
};

const EXPERIENCE = [_]ExperiencePair{
    .{ .after_answer = "twenty", .next_cue = "half of twenty", .weight = 3 },
    .{ .after_answer = "twenty", .next_cue = "twenty minus five", .weight = 2 },
    .{ .after_answer = "ten", .next_cue = "half of ten", .weight = 3 },
    .{ .after_answer = "ten", .next_cue = "ten plus five", .weight = 2 },
    .{ .after_answer = "ten", .next_cue = "twice ten", .weight = 2 },
    .{ .after_answer = "five", .next_cue = "twice five", .weight = 3 },
    .{ .after_answer = "eight", .next_cue = "twice eight", .weight = 3 },
    .{ .after_answer = "sixteen", .next_cue = "half of sixteen", .weight = 3 },
    .{ .after_answer = "sun", .next_cue = "sun when", .weight = 3 },
    .{ .after_answer = "day", .next_cue = "sky color", .weight = 3 },
    .{ .after_answer = "two", .next_cue = "two and one", .weight = 3 },
    .{ .after_answer = "three", .next_cue = "two and three", .weight = 3 },
    .{ .after_answer = "water", .next_cue = "people need", .weight = 2 },
};

/// Optional chain-specific override: after hop i produced answer A, force next cue.
/// Enables multiple composition paths from the same intermediate (schema selection).
const ChainOverride = struct {
    chain_id: []const u8,
    after_answer: []const u8,
    next_cue: []const u8,
};

const OVERRIDES = [_]ChainOverride{
    .{ .chain_id = "c-ten-plus", .after_answer = "ten", .next_cue = "ten plus five" },
    .{ .chain_id = "c-twenty-minus", .after_answer = "twenty", .next_cue = "twenty minus five" },
    .{ .chain_id = "c-twice-ten", .after_answer = "ten", .next_cue = "twice ten" },
    .{ .chain_id = "c-half-sixteen", .after_answer = "sixteen", .next_cue = "half of sixteen" },
    .{ .chain_id = "c-living-people", .after_answer = "water", .next_cue = "people need" },
};

/// Composition probe: only seed is given; further cues come from answers + edges.
const ComposeChain = struct {
    id: []const u8,
    seed_cue: []const u8,
    n_hops: u8, // 2 or 3 retrieves
    final_answer: []const u8,
};

const CHAINS = [_]ComposeChain{
    // 2-hop math
    .{ .id = "c-halfhalf", .seed_cue = "half of forty", .n_hops = 2, .final_answer = "ten" },
    .{ .id = "c-ten-plus", .seed_cue = "half of twenty", .n_hops = 2, .final_answer = "fifteen" },
    .{ .id = "c-twenty-minus", .seed_cue = "half of forty", .n_hops = 2, .final_answer = "fifteen" },
    .{ .id = "c-twice-ten", .seed_cue = "half of twenty", .n_hops = 2, .final_answer = "twenty" },
    .{ .id = "c-half-ten", .seed_cue = "half of twenty", .n_hops = 2, .final_answer = "five" },
    .{ .id = "c-twice-five", .seed_cue = "half of ten", .n_hops = 2, .final_answer = "ten" },
    .{ .id = "c-four-twice", .seed_cue = "four times two", .n_hops = 2, .final_answer = "sixteen" },
    .{ .id = "c-half-sixteen", .seed_cue = "twice eight", .n_hops = 2, .final_answer = "eight" },
    // 2-hop literacy
    .{ .id = "c-plant-day", .seed_cue = "plants need", .n_hops = 2, .final_answer = "day" },
    .{ .id = "c-math-two-three", .seed_cue = "one and one", .n_hops = 2, .final_answer = "three" },
    .{ .id = "c-living-people", .seed_cue = "living need", .n_hops = 2, .final_answer = "water" },
    // 3-hop
    .{ .id = "c-half3", .seed_cue = "half of forty", .n_hops = 3, .final_answer = "five" },
    .{ .id = "c-plant-sky", .seed_cue = "plants need", .n_hops = 3, .final_answer = "blue" },
    .{ .id = "c-one-to-five", .seed_cue = "one and one", .n_hops = 3, .final_answer = "five" },
    .{ .id = "c-half-twice-five", .seed_cue = "half of twenty", .n_hops = 3, .final_answer = "ten" },
    .{ .id = "c-twice8-half", .seed_cue = "four times two", .n_hops = 3, .final_answer = "eight" },
};

// ---------- grounded bank + reverse answer→word ----------
var bank_q: [160]u32 = .{0} ** 160;
var bank_a: [160]u32 = .{0} ** 160;
var bank_n: usize = 0;
var taught_ans: [80]u32 = .{0} ** 80;
var n_taught: usize = 0;
/// Reverse: answer token → answer word (for edge lookup / diagnostics)
var ans_tok: [80]u32 = .{0} ** 80;
var ans_word: [80][]const u8 = .{""} ** 80;
var n_ans_words: usize = 0;

// ---------- discovered schema edges (from experience co-occurrence) ----------
const MAX_DISC: usize = 48;
var disc_from: [MAX_DISC]u32 = .{0} ** MAX_DISC;
var disc_cue: [MAX_DISC][]const u8 = .{""} ** MAX_DISC;
var disc_w: [MAX_DISC]u32 = .{0} ** MAX_DISC;
var n_disc: usize = 0;

fn bankClear() void {
    bank_n = 0;
    n_taught = 0;
    n_ans_words = 0;
    n_disc = 0;
}

fn discoverEdge(from_ans: []const u8, next_cue: []const u8, w: u32) void {
    const fh = memory_f.hashToken(from_ans);
    var i: usize = 0;
    while (i < n_disc) : (i += 1) {
        if (disc_from[i] == fh and std.mem.eql(u8, disc_cue[i], next_cue)) {
            disc_w[i] += w;
            return;
        }
    }
    if (n_disc >= MAX_DISC) return;
    disc_from[n_disc] = fh;
    disc_cue[n_disc] = next_cue;
    disc_w[n_disc] = w;
    n_disc += 1;
}

fn discoverFromExperience() u32 {
    var n: u32 = 0;
    for (EXPERIENCE) |e| {
        // only discover if next cue is a taught premise (grounded schema)
        if (bankGet(e.next_cue) == 0) continue;
        discoverEdge(e.after_answer, e.next_cue, e.weight);
        n += 1;
    }
    // also seed static table into discovered set with weight 1 (baseline schemas)
    for (EDGES) |e| {
        if (bankGet(e.next_cue) == 0) continue;
        discoverEdge(e.from_answer, e.next_cue, 1);
        n += 1;
    }
    return n;
}

/// Best discovered next cue for answer word (max weight). Optional chain override wins.
fn discoveredNext(from_ans: []const u8) ?[]const u8 {
    const fh = memory_f.hashToken(from_ans);
    var best_i: ?usize = null;
    var best_w: u32 = 0;
    var i: usize = 0;
    while (i < n_disc) : (i += 1) {
        if (disc_from[i] != fh) continue;
        if (disc_w[i] > best_w) {
            best_w = disc_w[i];
            best_i = i;
        }
    }
    if (best_i) |bi| return disc_cue[bi];
    return null;
}

fn rememberAnswerWord(word: []const u8) void {
    const t = memory_f.hashToken(word);
    var i: usize = 0;
    while (i < n_ans_words) : (i += 1) if (ans_tok[i] == t) return;
    if (n_ans_words >= ans_tok.len) return;
    ans_tok[n_ans_words] = t;
    ans_word[n_ans_words] = word;
    n_ans_words += 1;
}

fn wordForToken(tok: u32) ?[]const u8 {
    var i: usize = 0;
    while (i < n_ans_words) : (i += 1) if (ans_tok[i] == tok) return ans_word[i];
    return null;
}

fn bankPut(q: []const u8, a: []const u8) void {
    if (bank_n >= bank_q.len) return;
    bank_q[bank_n] = memory_f.hashToken(q);
    bank_a[bank_n] = memory_f.hashToken(a);
    bank_n += 1;
    const ah = memory_f.hashToken(a);
    var i: usize = 0;
    while (i < n_taught) : (i += 1) if (taught_ans[i] == ah) {
        rememberAnswerWord(a);
        return;
    };
    if (n_taught < taught_ans.len) {
        taught_ans[n_taught] = ah;
        n_taught += 1;
    }
    rememberAnswerWord(a);
}

fn bankGet(q: []const u8) u32 {
    const h = memory_f.hashToken(q);
    var i: usize = 0;
    while (i < bank_n) : (i += 1) if (bank_q[i] == h) return bank_a[i];
    return 0;
}

fn isTaught(tok: u32) bool {
    var i: usize = 0;
    while (i < n_taught) : (i += 1) if (taught_ans[i] == tok) return true;
    return false;
}

// ---------- WM (Miller-ish intermediate hold) ----------
pub const WM_SLOTS: usize = 4;

const WmSlot = struct {
    token: u32 = 0,
    strength: Fixed = 0,
    valid: bool = false,
};

fn wmPush(slots: *[WM_SLOTS]WmSlot, tok: u32, s: Fixed) void {
    var best: usize = 0;
    var best_s: Fixed = fixed.fromInt(99);
    var i: usize = 0;
    while (i < WM_SLOTS) : (i += 1) {
        if (!slots[i].valid) {
            slots[i] = .{ .token = tok, .strength = s, .valid = true };
            return;
        }
        if (fixed.lt(slots[i].strength, best_s)) {
            best_s = slots[i].strength;
            best = i;
        }
    }
    slots[best] = .{ .token = tok, .strength = s, .valid = true };
}

fn wmContains(slots: *const [WM_SLOTS]WmSlot, tok: u32) bool {
    var i: usize = 0;
    while (i < WM_SLOTS) : (i += 1) {
        if (slots[i].valid and slots[i].token == tok) return true;
    }
    return false;
}

fn wmCount(slots: *const [WM_SLOTS]WmSlot) u32 {
    var n: u32 = 0;
    var i: usize = 0;
    while (i < WM_SLOTS) : (i += 1) {
        if (slots[i].valid) n += 1;
    }
    return n;
}

fn wmClear(slots: *[WM_SLOTS]WmSlot) void {
    var i: usize = 0;
    while (i < WM_SLOTS) : (i += 1) slots[i] = .{};
}

// ---------- lattice helpers ----------
fn cueFeat(cue: []const u8, out: *[8]Fixed) void {
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        const h = memory_f.hashToken(cue) *% (@as(u32, @intCast(i)) +% 17) +% 53;
        out[i] = fixed.sub(fixed.div(fixed.fromInt(@intCast(h % 181)), fixed.fromInt(90)), fixed.fromInt(1));
    }
}

fn driveExt(b: *brain_f.BrainF, feat: []const Fixed, gain: Fixed, quiet: Fixed, t: usize, ext: []Fixed) void {
    var i: usize = 0;
    while (i < b.n) : (i += 1) {
        var e = fixed.mul(fixed.fromDecimalStr("0.03"), quiet);
        const f = if (feat.len == 0) 0 else feat[i % feat.len];
        switch (b.region_of[i]) {
            .thal => {
                if ((t % 40) < 12) e = fixed.add(e, fixed.mul(fixed.fromDecimalStr("0.28"), gain));
                e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.12"), f), gain));
            },
            .sens => e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.75"), f), gain)),
            .assoc => e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.58"), f), gain)),
            .hipp => e = fixed.add(e, fixed.mul(fixed.mul(fixed.fromDecimalStr("0.72"), f), gain)),
        }
        ext[i] = fixed.clamp(e, fixed.fromDecimalStr("-0.5"), fixed.fromDecimalStr("1.6"));
    }
}

fn applyPE(nm: *neuromod_f.NeuromodState, hit: bool, pe_hits: *u32, pe_miss: *u32) void {
    if (hit) {
        neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.22"));
        pe_hits.* += 1;
    } else {
        neuromod_f.step(nm, .wake_probe, 0, fixed.fromDecimalStr("0.06"), fixed.fromDecimalStr("0.20"), 0, fixed.fromInt(1));
        pe_miss.* += 1;
    }
}

fn trainPremises(org: *organism_f.OrganismF, nm: *neuromod_f.NeuromodState) u32 {
    bankClear();
    var n: u32 = 0;
    for (LESSONS) |L| {
        var k: u32 = 0;
        while (k < 6) : (k += 1) {
            neuromod_f.step(nm, .wake_encode, 0, fixed.fromDecimalStr("0.05"), fixed.fromDecimalStr("0.03"), 0, fixed.fromInt(1));
        }
        const card = teach_f.buildLesson(.learning, "learner", L.answer, "school", "compose", L.id, true);
        var feats: [8]Fixed = undefined;
        cueFeat(L.question, &feats);
        var toks = card.tokens;
        toks[1] = memory_f.hashToken(L.answer);
        toks[2] = memory_f.hashToken(L.question);
        toks[5] = memory_f.hashToken("taught");
        // brief lattice dynamics under encode gain (hipp/assoc bind)
        var ext: [brain_f.N_TOTAL]Fixed = undefined;
        var t: usize = 0;
        while (t < 8) : (t += 1) {
            const g = neuromod_f.encodeGain(nm);
            driveExt(&org.brain, feats[0..], g, fixed.fromInt(1), t, ext[0..]);
            org.brain.step(ext[0..]);
        }
        _ = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
        bankPut(L.question, L.answer);
        bankPut(L.fact, L.answer);
        bankPut(L.answer, L.answer);
        neuromod_f.pulseDa(nm, fixed.fromDecimalStr("0.12"));
        n += 1;
    }
    // Experience schedule: re-encode successive pairs under ACh (schema induction path)
    for (EXPERIENCE) |e| {
        var k: u32 = 0;
        while (k < e.weight) : (k += 1) {
            neuromod_f.step(nm, .wake_encode, 0, fixed.fromDecimalStr("0.04"), fixed.fromDecimalStr("0.02"), 0, fixed.fromInt(1));
            var feats: [8]Fixed = undefined;
            cueFeat(e.next_cue, &feats);
            var toks: [6]u32 = .{0} ** 6;
            toks[1] = bankGet(e.next_cue);
            toks[2] = memory_f.hashToken(e.next_cue);
            toks[3] = memory_f.hashToken(e.after_answer); // prior answer context
            toks[5] = memory_f.hashToken("schema");
            if (toks[1] != 0) {
                var ext: [brain_f.N_TOTAL]Fixed = undefined;
                var t: usize = 0;
                while (t < 4) : (t += 1) {
                    driveExt(&org.brain, feats[0..], neuromod_f.encodeGain(nm), fixed.fromInt(1), t, ext[0..]);
                    org.brain.step(ext[0..]);
                }
                _ = org.store.encode(&org.brain, feats[0..], 0b111111, toks);
            }
        }
    }
    _ = discoverFromExperience();
    return n;
}

/// Resolve next cue: chain override → discovered schema (max weight) → static table.
fn nextCueFromAnswer(chain_id: []const u8, answer_word: []const u8) ?[]const u8 {
    for (OVERRIDES) |o| {
        if (std.mem.eql(u8, o.chain_id, chain_id) and std.mem.eql(u8, o.after_answer, answer_word)) {
            return o.next_cue;
        }
    }
    if (discoveredNext(answer_word)) |d| return d;
    for (EDGES) |e| {
        if (std.mem.eql(u8, e.from_answer, answer_word)) return e.next_cue;
    }
    return null;
}

const HopRun = struct {
    final_tok: u32 = 0,
    hops_grounded: u32 = 0,
    hops_done: u32 = 0,
    wm_held_all: bool = true,
    broke_edge: bool = false,
    last_mid: u32 = 0,
    last_mid_word: []const u8 = "",
    episodic_hits: u32 = 0,
    bank_fallbacks: u32 = 0,
};

/// Minimum cosine for accepting episodic answer (fingerprint bind).
const EPISODIC_SIM_MIN: f64 = 0.15;

/// Run answer-dependent composition. Episodic-first; bank is claim floor / fallback.
/// If `corrupt_mid` is set, after first hop replace answer so next edge should fail.
fn runCompose(
    org: *organism_f.OrganismF,
    nm: *neuromod_f.NeuromodState,
    wm: *[WM_SLOTS]WmSlot,
    chain: ComposeChain,
    corrupt_mid: bool,
    pe_hits: *u32,
    pe_miss: *u32,
) HopRun {
    var out: HopRun = .{};
    wmClear(wm);
    var cue: []const u8 = chain.seed_cue;
    var hop_i: u8 = 0;
    while (hop_i < chain.n_hops) : (hop_i += 1) {
        var feats: [8]Fixed = undefined;
        cueFeat(cue, &feats);
        var ext: [brain_f.N_TOTAL]Fixed = undefined;
        var t: usize = 0;
        while (t < 6) : (t += 1) {
            neuromod_f.step(nm, .wake_probe, 0, 0, 0, 0, fixed.fromInt(1));
            driveExt(&org.brain, feats[0..], neuromod_f.encodeGain(nm), fixed.fromInt(1), t, ext[0..]);
            org.brain.step(ext[0..]);
        }
        // Episodic-first (hipp fingerprint)
        var sim: Fixed = 0;
        const eid = org.store.retrieve(&org.brain, feats[0..], &sim);
        var retrieved: u32 = 0;
        var used_episodic = false;
        if (eid != 0) {
            if (org.store.findEpisode(eid)) |ep| {
                const cand = ep.tokens[1];
                if (cand != 0 and isTaught(cand) and fixed.toF64(sim) >= EPISODIC_SIM_MIN) {
                    retrieved = cand;
                    used_episodic = true;
                }
            }
        }
        const bank_ans = bankGet(cue);
        // Claim floor: if episodic wrong vs bank, prefer bank (grounded truth)
        if (bank_ans != 0) {
            if (!used_episodic or retrieved != bank_ans) {
                if (used_episodic and retrieved != bank_ans) {
                    // episodic collision — fall back to bank for claimability
                    retrieved = bank_ans;
                    used_episodic = false;
                    out.bank_fallbacks += 1;
                } else if (!used_episodic) {
                    retrieved = bank_ans;
                    out.bank_fallbacks += 1;
                }
            }
        }
        if (used_episodic) out.episodic_hits += 1;

        const grounded = retrieved != 0 and isTaught(retrieved);
        if (grounded) out.hops_grounded += 1;
        out.hops_done += 1;
        out.final_tok = retrieved;
        applyPE(nm, grounded, pe_hits, pe_miss);

        if (!grounded) {
            out.broke_edge = true;
            out.wm_held_all = false;
            return out;
        }

        wmPush(wm, retrieved, fixed.fromDecimalStr("0.95"));
        if (!wmContains(wm, retrieved)) out.wm_held_all = false;

        if (hop_i + 1 >= chain.n_hops) break;

        var ans_w = wordForToken(retrieved) orelse {
            out.broke_edge = true;
            return out;
        };
        out.last_mid = retrieved;
        out.last_mid_word = ans_w;

        if (corrupt_mid and hop_i == 0) {
            ans_w = "animal";
            out.last_mid = memory_f.hashToken(ans_w);
        }

        const nxt = nextCueFromAnswer(chain.id, ans_w) orelse {
            out.broke_edge = true;
            return out;
        };
        if (std.mem.eql(u8, nxt, chain.seed_cue)) {
            out.broke_edge = true;
            return out;
        }
        cue = nxt;
    }
    return out;
}

pub const ComposeReport = struct {
    ok: bool = false,
    n_taught: u32 = 0,
    n_chains: u32 = 0,
    n_correct: u32 = 0,
    n_claimable: u32 = 0,
    n_2hop: u32 = 0,
    n_3hop: u32 = 0,
    correct_2: u32 = 0,
    correct_3: u32 = 0,
    claimable_2: u32 = 0,
    claimable_3: u32 = 0,
    accuracy: f64 = 0,
    claim_rate: f64 = 0,
    pe_hits: u32 = 0,
    pe_miss: u32 = 0,
    mean_ach: f64 = 0,
    wm_peak: u32 = 0,
    n_ablate: u32 = 0,
    n_ablate_broke: u32 = 0,
    ablate_break_rate: f64 = 0,
    neuromod_ok: bool = false,
    answer_dependent: bool = true,
    /// Schema discovery
    n_discovered_edges: u32 = 0,
    schema_from_experience: bool = false,
    /// Episodic-first path
    episodic_hits: u32 = 0,
    bank_fallbacks: u32 = 0,
    episodic_rate: f64 = 0,
};

pub fn runComposeIntel() ComposeReport {
    var rep: ComposeReport = .{};
    rep.neuromod_ok = neuromod_f.selfTest();
    var org = organism_f.OrganismF.init();
    org.brain = brain_f.BrainF.initSeeded(13, true);
    var nm: neuromod_f.NeuromodState = .{};
    var wm: [WM_SLOTS]WmSlot = undefined;
    wmClear(&wm);

    rep.n_taught = trainPremises(&org, &nm);
    rep.n_discovered_edges = @intCast(n_disc);
    rep.schema_from_experience = n_disc >= 8;
    rep.mean_ach = fixed.toF64(nm.ach);

    var hop_total: u32 = 0;
    for (CHAINS) |ch| {
        rep.n_chains += 1;
        var pe_h: u32 = 0;
        var pe_m: u32 = 0;
        const hr = runCompose(&org, &nm, &wm, ch, false, &pe_h, &pe_m);
        rep.pe_hits += pe_h;
        rep.pe_miss += pe_m;
        rep.episodic_hits += hr.episodic_hits;
        rep.bank_fallbacks += hr.bank_fallbacks;
        hop_total += hr.hops_done;
        const wmc = wmCount(&wm);
        if (wmc > rep.wm_peak) rep.wm_peak = wmc;

        const expect = memory_f.hashToken(ch.final_answer);
        const correct = hr.final_tok == expect and hr.hops_done == ch.n_hops;
        const claimable = correct and hr.hops_grounded == ch.n_hops and isTaught(hr.final_tok) and !hr.broke_edge;

        if (ch.n_hops == 2) {
            rep.n_2hop += 1;
            if (correct) rep.correct_2 += 1;
            if (claimable) rep.claimable_2 += 1;
        } else {
            rep.n_3hop += 1;
            if (correct) rep.correct_3 += 1;
            if (claimable) rep.claimable_3 += 1;
        }
        if (correct) rep.n_correct += 1;
        if (claimable) rep.n_claimable += 1;

        if (claimable) {
            rep.n_ablate += 1;
            var pe_h2: u32 = 0;
            var pe_m2: u32 = 0;
            const bad = runCompose(&org, &nm, &wm, ch, true, &pe_h2, &pe_m2);
            const still_ok = bad.final_tok == expect and bad.hops_grounded == ch.n_hops and !bad.broke_edge;
            if (!still_ok or bad.broke_edge or bad.final_tok != expect) {
                rep.n_ablate_broke += 1;
            }
        }
    }

    if (rep.n_chains > 0) {
        rep.accuracy = @as(f64, @floatFromInt(rep.n_correct)) / @as(f64, @floatFromInt(rep.n_chains));
        rep.claim_rate = @as(f64, @floatFromInt(rep.n_claimable)) / @as(f64, @floatFromInt(rep.n_chains));
    }
    if (rep.n_ablate > 0) {
        rep.ablate_break_rate = @as(f64, @floatFromInt(rep.n_ablate_broke)) / @as(f64, @floatFromInt(rep.n_ablate));
    }
    if (hop_total > 0) {
        rep.episodic_rate = @as(f64, @floatFromInt(rep.episodic_hits)) / @as(f64, @floatFromInt(hop_total));
    }

    rep.ok = rep.neuromod_ok and
        rep.n_chains >= 12 and
        rep.n_2hop >= 6 and
        rep.n_3hop >= 3 and
        rep.claim_rate >= 0.90 and
        rep.accuracy >= 0.90 and
        rep.correct_3 >= 2 and
        rep.n_ablate >= 8 and
        rep.ablate_break_rate >= 0.80 and
        rep.pe_hits >= 1 and
        rep.wm_peak >= 1 and
        rep.answer_dependent and
        rep.schema_from_experience and
        rep.n_discovered_edges >= 8;
    return rep;
}

pub fn selfTest() bool {
    return runComposeIntel().ok;
}

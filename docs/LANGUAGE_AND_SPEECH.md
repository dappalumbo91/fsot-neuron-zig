# Language and speech (Zig student)

**Doctrine:** The mind’s native tongue is **machine language** (TritWord / FSOT frames).  
English is a **codec** (lexicon + TTS plant). Any LLM/Ollama teacher lives **outside** this repo’s runtime and only grows data in the monorepo.

## Zig modules (this repo)

| Module | Role |
|--------|------|
| `machine_lang_fixed.zig` | Generate / parse FSOT frames; round-trip |
| `machine_encode_fixed.zig` | Bytes/UTF-8 ↔ trits |
| `lexicon_en_fixed.zig` | English word ↔ role ↔ choose-by-meaning |
| `host_tts_fixed.zig` | Windows SAPI TTS plant |
| `language_practice_fixed.zig` | Utter → TTS → self-re-ingest → encode |
| `grade_practice_fixed.zig
| `reason_practice_fixed.zig` | Multi-hop open reason + process log |` | PK/K/G1 teach facts → quiz → solve |
| `mind_live_fixed.zig` | Live organism: EN_SAY + machine frames + TTS |
| `ambient_scene_fixed.zig` | Auditory scene filter |
| `attention_fixed.zig` / `eeg_gate_anchors_fixed.zig` | Attention gates |
| `speech_organ_fixed.zig` | Optional formant/motor plant (not primary language) |

## Modes

```text
fsot_mind machine-lang          # native tongue
fsot_mind machine-lang-stress   # 1000-frame stress
fsot_mind english               # lexicon + one TTS line
fsot_mind practice              # self-hear language loop
fsot_mind grade                 # facts + problems apply
fsot_mind mind                  # full connected organism
fsot_mind reason              # open multi-hop reason (bio process)
fsot_mind stress                # fixed suite
```

Windows TEMP build (if `zig-out` locked):

```powershell
$out = "$env:TEMP\fsot_mind_live.exe"
$cache = "$env:TEMP\fsot_zig_cache_live"
zig build-exe -OReleaseFast "-femit-bin=$out" --cache-dir $cache --name fsot_mind_live src/main_mind.zig -lgdi32 -luser32 -lwinmm
& $out grade
& $out mind
```

## Lexicon data

Runtime can load `en_roles.tsv` from the monorepo path if present:

- `I:/fsot nuron/data/lexicon/en_roles.tsv` (dev machine)
- or `data/lexicon/en_roles.tsv` relative to cwd

Embedded core words always work without external files.  
**Growing the lexicon / curriculum** is done in the monorepo:

- https://github.com/dappalumbo91/FSOT-2.1-Neural  
- `docs/LANGUAGE_LEARNING_METHODOLOGY.md`

Teacher scripts (Python + Ollama) are monorepo-only by design: they are **not** the mind.

# Speech / thinking EEG as a bounce-off metric

**Yes — this is a better fit for our architecture than LLM leaderboards.**

Humans do not “score GSM8K” while speaking. Their brains show **measurable phase structure** while they:

1. **Hear / attend** language  
2. **Retrieve / select meaning** (think from what was learned)  
3. **Prepare articulation** (motor plan)  
4. **Speak** (overt production)  
5. **Self-hear** (re-afferent auditory feedback, often suppressed vs others’ speech)  
6. **Encode** the exchange (memory for later turns)

That timeline is a **scientific target** for a genetic Fixed organism under FSOT — not a chat API score.

---

## What public human data exists (usable sources)

| Source | Content | How we use it |
|--------|---------|----------------|
| **OpenNeuro ds003626** — *Thinking out loud* (Nieto et al., Sci Data 2022) | Inner speech EEG BCI (multiclass commands) | Phase: **covert think / prepare**, not TTS |
| **OpenNeuro EEG–speech production** (e.g. ds007808 / ds007602 family) | Overt speech + audio | Phase: **produce** + audio alignment |
| **OpenNeuro ds006104** | Phoneme / speech decoding EEG | Sensory / articulatory feature decoding |
| **OpenNeuro EEG–fMRI inner speech** (ds006033) | Simultaneous modalities | Cross-check, later depth |
| **ERP literature** (picture naming, overt speech) | P2 ~ lexical access ~200 ms; N400 semantics; motor prep | **Ordered timeline** priors (not raw EDF required) |
| **Speaker-induced suppression** | Own voice early auditory components reduced vs listening | Matches our **self-hear / re-afferent** path |
| **Sederberg SME (2003)** | Successful encode ↑ θ + γ (iEEG) | Already in `eeg_gate_anchors_fixed` |
| **Indefrey & Levelt meta-timeline** | Concept → lemma → phonology → articulatory → acoustic | Maps 1:1 to: retrieve → engram → motor → acoustic |

**Honesty:** Full raw multi-GB EDF packs need offline prep (like MNIST pack). Day-one use is **literature + derived priors** locked into Fixed anchors (same pattern as concentrate/relax study EEG already in-tree). Later: export speech-phase feature packs from OpenNeuro and FSOT-couple them (zero free LSQ).

---

## Map human EEG phases → our stack

| Human phase (EEG / ERP spirit) | FSOT organism path |
|--------------------------------|--------------------|
| Attend partner speech | `pushSense` text/audio · attention figure gain |
| Semantic / meaning access (~N400 window spirit) | `store.retrieve` + `SpeakEngram` load |
| Lexical / form preparation | engram phrase + meaning features |
| Articulatory motor | `speakNow` / formant motor plant |
| Acoustic output | host TTS or formant DAC (plant, not mind) |
| Self-monitoring / suppression | `self_hear` · residual · `adaptSpeechFromHear` |
| Successful encoding of turn | episodic encode + DA pulse (SME spirit) |

**Pass idea (bio, not LLM):**  
During `bio-converse`, report **phase ordering** and **SME-style encode open** when meaning+self align — bounce organism dynamics off EEG doctrine, not token accuracy alone.

---

## Already in this repo

| Module | Role |
|--------|------|
| `eeg_gate_anchors_fixed.zig` | θ/α concentrate vs relax, SME θ/γ encode, self-match, figure/ground |
| `attention_fixed.zig` | attune / encode_open from EEG weights |
| `mind_live_fixed.zig` | uses self-hear thresh from EEG anchors |
| `bands_fixed.zig` / SME modes | study-band spirit |

**Gap (closing):** speech-**production** timeline priors and a **speech-phase** report on multi-turn converse — not only “study vs rest.”

---

## What we refuse

- Using EEG as an excuse to train a **decoder LLM** on scalp data and call that the mind.  
- Free-parameter fitting of hundreds of ERP peaks.  

**We do:** lock **directional, literature + measured** anchors under FSOT seeds (same doctrine as existing study EEG).

---

## Modes / next work

1. Anchors: speech-phase timing + speaker-suppression + SME-on-turn-encode in `eeg_gate_anchors_fixed`.  
2. Probe: `fsot_mind speech-eeg` — run bio-converse and print phase alignment vs anchors.  
3. Later: OpenNeuro-derived **feature pack** (like MNIST pack) for φ-coupled band ratios during inner vs overt speech.

See also: [`BIO_LEARNING_DOCTRINE.md`](BIO_LEARNING_DOCTRINE.md), [`SPEECH_ORGAN_DOCTRINE.md`](SPEECH_ORGAN_DOCTRINE.md).

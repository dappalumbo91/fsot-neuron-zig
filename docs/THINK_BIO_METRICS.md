# Think run — biological metrics (not LLM)

**Binding:** readings on long think are **process-accurate bio metrics**, not GSM8K / chat scores.

## Sleep schedule (each `sleep_every` cycles)

| Phase | Neuromod | Role |
|-------|----------|------|
| `wake_rest` | low DA/ACh/NE, rising 5-HT | descend arousal |
| `sleep_nrem` | ACh/NE low, 5-HT high | quiet SWS-like offline |
| `sleep_replay` | DA pulse + low ACh | associative reactivation (SWR analogue) |

- **Light sleep** (3 of 4): CPU Fixed pair cosine/trit → co-activate episodes  
- **Deep sleep** (every 4th): full **VRAM** matrix → FSOT-GPU consensus → top-K → replay  

## Heartbeat fields

| Field | Bio meaning |
|-------|-------------|
| `episodic_retr` | encode→retrieve fidelity on grown cues (not chat accuracy) |
| `curiosity` | unknown-word query hit rate (curiosity / tool use) |
| `pending` | open questions parked (move on, not thrash) |
| `stm_grown` / `life` | hot working set vs lifetime knowledge |
| `ltm_spill` | cold pages written to disk (growth unbounded) |
| `sleep` / `replay` | offline events + pair reactivations |
| `da` / `ach` | process-scale neuromod snapshot |
| `batch_cos` | mean similarity of last replay pairs |
| `deep_vram` | count of VRAM deep consolidations |

## Accuracy JSONL (`THINK_ACCURACY.jsonl`)

```json
{
  "metric_kind": "bio_episodic_not_llm",
  "episodic_retrace": 1.0,
  "curiosity_hit": 0.82,
  "stm_grown": 400,
  "life_grown": 900,
  "ltm_spill": 12,
  "n_sleep": 20,
  "batch_replay": 80,
  "mean_da": 0.12,
  "mean_ach": 0.08,
  "mean_batch_cos": 0.55
}
```

Aliases `retrace_acc` / `discover_acc` kept for older readers.

## Doctrine checklist

- [x] Wake encode uses `wake_encode` + DA pulse on study  
- [x] Retrace uses `wake_probe` + DA on correct recall  
- [x] Miss → re-experience (not SGD epoch)  
- [x] Sleep ordered rest → NREM → replay  
- [x] Pending questions on query miss  
- [x] Stuck auto-stop  
- [x] No LLM primary benchmarks  

See [`BIO_LEARNING_DOCTRINE.md`](BIO_LEARNING_DOCTRINE.md).

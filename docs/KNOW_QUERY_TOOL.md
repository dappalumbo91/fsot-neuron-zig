# Know-query tool study (human “I don’t know”)

**Mode:** `fsot_mind know-query` · `know-query-live`  
**Code:** `query_tool_fixed.zig` · `know_query_fixed.zig`  
**Archive curriculum:** `I:\FSOT-Physical-Archive` (OpenAlex cache, oracle streams, live API policy)

## Human pattern

```text
probe concept
  → if engram/retrieve hit: already known
  → else: mark unknown ("I don't know table")
       → query tool (local archive first, optional live Wikipedia)
       → study definition → encode + SpeakEngram (retain)
       → re-probe from memory only
```

Example: **table** → not known → query → “a flat surface with legs…” → retain → later “table” retrieves without re-query.

## Tool sources (order)

| Priority | Source | Path / API |
|----------|--------|------------|
| 1 | Embedded seed | offline (offline smoke) |
| 2 | Dictionary | `data/lexicon/en_dictionary.jsonl` |
| 3 | Simple Wiki | `D:\training data\nlp\simple-wiki\…` |
| 4 | OpenAlex cache | `I:\FSOT-Physical-Archive\03_FSOT-PublicData\openalex\` |
| 5 | arXiv / oracle streams | `D:\training data\arxiv_fsot_core.txt` + archive `stream_*.txt` |
| 6 | Live (optional) | Wikipedia REST summary (credential-free) |

Matches Physical Archive spirit: **local first**, credential-free APIs when allowed (`public_api_policy` / live fetch curriculum).

## Commands

```text
fsot_mind know-query        # local only
fsot_mind know-query-live   # + Wikipedia if local miss
fsot_mind study-tool        # alias
```

## Not this

- Not stuffing GSM8K/MMLU as the learning goal  
- Not an LLM chat that pretends to “know” without encode  
- Not raw web dump without retain → re-probe proof  

## Pending questions (stuck → note → move on)

When lookup fails or the definition is unusable, the mind **does not loop**.

It writes one JSONL line to:

`data/results/THINK_PENDING_QUESTIONS.jsonl`

```json
{"id":3,"status":"open","question":"what is foobar?","reason":"query_miss","context":"...","cycle":42}
```

Reasons: `query_miss` | `def_unusable`  

Later you (or a live API pass) can answer these; the organism already encoded an “unknown/pending” episode and continues thinking.

## Next

- Resolve pending questions via `know-query-live` batch  
- Live OpenAlex query (archive mailto policy) when cache miss  


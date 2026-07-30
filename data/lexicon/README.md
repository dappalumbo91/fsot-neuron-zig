# English lexicon — dictionary + thesaurus foundation

Built from **Princeton WordNet** (via NLTK): lemma, part of speech, definition, example usage, synonyms.

## Doctrine

| Layer | Role |
|-------|------|
| **Core WORDS** (embedded in `lexicon_en_fixed.zig`) | Grammar templates for TTS generation (safe English) |
| **en_roles.tsv** | Large recognition vocabulary (dictionary import) |
| **en_dictionary.jsonl** | Full cards: definition, usage, synonyms, antonyms |
| **en_synonyms.tsv** | Thesaurus links |
| **dictionary_lessons.tsv** | “what does X mean” lessons for `brain-learn` |

The mind does **not** free-associate 20k words into sentences (that caused word salad).  
It **recognizes** dictionary words on input and **speaks** with core grammar templates; definitions teach meaning offline/online via school.

## Rebuild from dictionary

```powershell
cd "I:\fsot nuron"
$env:PYTHONPATH = "I:\fsot nuron"
python scripts/build_lexicon_from_dictionary.py --ensure-wordnet --max-words 20000
# copies into this data/lexicon/
```

## Load at runtime

`fsot_mind english` / `practice` / `mind` call `tryLoadDefaultRoles()` → reads `data/lexicon/en_roles.tsv`.

Capacity: up to **32768** extra entries in Zig (`MAX_EXTRA`).

## Sources

- Princeton WordNet (research license) — primary dictionary/thesaurus
- Optional older teacher bulk still mergeable via same TSV format

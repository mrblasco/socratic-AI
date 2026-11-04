# LLM annotation pipeline

Rates the student–AI chats with a panel of LLMs and measures rater reliability.
It is separate from the empirical analysis and the manuscript: its only input is
`input/dialogues.json` (built from the `socraticaidata` R package), and the
analysis reads only from `input/` (ID lists) and `output/` (collected ratings and
reliability tables).

> **Status (2026-11-04): input rebuilt, ratings not yet redone.** The ratings in
> `ratings/` and `output/` were made on `input/dialogues_v1.json`, which has a
> bug (see *Chat IDs* below). `input/dialogues.json` is now correct, but nothing
> has been re-rated yet.

```
socraticaidata::chats ──export──▶ input/dialogues.json ──rate──▶ ratings/<run>/*.json
                                                                │ collect
                                                                ▼
                      ../analysis.R ◀── output/*.csv ◀── reliability
```

## Layout

| Path | Contents |
|---|---|
| `prompts/` | Rubrics: `rate_student.txt`, `rate_socratic.txt` (pre-specified), `rate_tutor.txt` (dropped from the panel). |
| `src/eval_dialogue.py` | `rate` (one model × one rubric, resumable, schema-constrained) and `collect` (raw JSON → long CSV). |
| `src/reliability.py` | Krippendorff's alpha (repeats, between models), MAD, Spearman, AC1; largest disagreements. |
| `scripts/run_holdout.sh` | The pre-specified holdout run (314 chats). |
| `scripts/run_panel.sh` | Generic panel runner for development rounds. |
| `scripts/check_prespec.sh` | Checks prompts and `../docs/prespecification.md` against `ratings/holdout/PRESPEC.sha256`. |
| `scripts/export_dialogues.R` | `socraticaidata::chats` → `input/dialogues.json` (366 chats, test account dropped). |
| `input/` | **Current:** `dialogues.json` (366, package IDs). **v1, matching the existing ratings (original IDs):** `dialogues_v1.json` (354), `holdout_ids.json` (314), `dev_subset_ids.json` (40). New dev/holdout splits on package IDs are still to be drawn. |
| `ratings/` | One raw JSON per chat × rep, plus `manifest.json` per run. `holdout/` (final), `dev_v1`–`dev_v3` (rubric development). |
| `output/` | `llm_ratings_holdout_long.csv`, `llm_ratings_dev_v{1,3}_long.csv`, `reliability_holdout/`, `reliability_dev_v3/`. |
| `legacy/` | First-generation ratings (`cognitive_engagement.*`, `dialogues.csv`, `dialogues_socratic_eval.csv`, 2025-11-13 JSON), their prompts and jq converters, and the old `requirements.txt`. Still read by `../dialog.R`, `../R/dialog2.R` and `../manuscript/03-results.Rmd`. |

## Usage

Run from this folder. API keys go in `OPENAI_API_KEY` / `ANTHROPIC_API_KEY`
(the environment, or a `.env` here or in the repo root).

```sh
make setup          # uv sync
make check-prespec  # pre-specified files unchanged?
make outputs        # rebuild output/ holdout CSVs from ratings/ (offline)
make holdout        # (re)run the holdout ratings; skips chats already rated
```

Development round with other models/rubrics:

```sh
REPS=2 MODELS="openai:gpt-4o anthropic:claude-sonnet-5-5" \
  scripts/run_panel.sh ratings/dev_v4 input/<dev_ids>.json
uv run python src/eval_dialogue.py collect --out ratings/dev_v4 --csv output/llm_ratings_dev_v4_long.csv
uv run python src/reliability.py --csv output/llm_ratings_dev_v4_long.csv --out output/reliability_dev_v4
```

## Chat IDs (v1 bug)

In `../analysis/data/processed/chats.rds`, `user_id` and `chat_id` restart at
1 in each school (Brussels, Seville). The v1 export grouped by `chat_id` only, so:

- the input looked like it came from 86 students; the true count is 120 (121
  users in `socraticaidata::chats`, minus the Seville test account, package
  `user_id` 120);
- 12 v1 dialogues (holdout `175 179 184 185 199 202 211 222 226 228 229 234`)
  each merged one Brussels chat and one Seville chat, so their ratings are invalid.

`socraticaidata::chats` replaces the student IDs with random ones for
anonymity, and its IDs are **not** to be linked back to the v1 (original) IDs. So
v1 ratings cannot be carried over to the new input: the chats need to be
re-rated on `input/dialogues.json`, with dev/holdout splits drawn on the package
IDs. Changing the holdout from the 314 chats in `../docs/prespecification.md`
is a deviation and must be reported as one.

`../analysis.R` still reads the v1 ID lists, and its chat-level covariates have
the same per-school ID problem; it has not been changed yet.

## Provenance notes

- The pipeline was moved here from the repo root on 2026-11-04. Saved records
  (`manifest.json`, per-chat JSON) and `PRESPEC.sha256` keep their original
  paths (`config/prompts/…`, `data/llm_ratings/…`, `analysis/data/dialogues.json`).
  Prompt contents and hashes did not change, so run-directory names and
  `prompt_hash` values still match. `../docs/prespecification.md` also uses the
  old paths; it is left unchanged because its hash is recorded.
- Old → new: `config/prompts/` → `prompts/`; `data/llm_ratings/` → `ratings/holdout/`;
  `data/llm_ratings_dev{,_v2,_v3}/` → `ratings/dev_v{1,2,3}/`;
  `data/llm_ratings_long.csv` → `output/llm_ratings_holdout_long.csv`;
  `data/*_ids.json`, `analysis/data/dialogues.json` → `input/`;
  `scripts/evaluate_chats/` → `src/`, `scripts/`.
- `make outputs` reproduces the committed holdout CSVs byte for byte.
  `output/reliability_dev_v3/` was computed on the haiku vs gpt-4o-mini pair only;
  see the note in the `Makefile`.
- No script here makes `holdout_ids.json` / `dev_subset_ids.json`; they are
  fixed inputs.

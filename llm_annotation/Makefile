# LLM annotation pipeline. Run `make <target>` from llm_annotation/.
# API keys: OPENAI_API_KEY / ANTHROPIC_API_KEY in the environment or a .env file.

PY := uv run python

.PHONY: help setup export check-prespec holdout collect reliability dev-v3 outputs colliding clean-holdout

help:
	@echo "setup          install the Python env (uv sync)"
	@echo "export         socraticaidata::chats -> input/dialogues.json"
	@echo "check-prespec  verify prompts + prespecification match PRESPEC.sha256"
	@echo "holdout        rate the 314 holdout chats (calls the APIs; resumable)"
	@echo "outputs        rebuild holdout CSVs in output/ from ratings/ (no API calls)"
	@echo "clean-holdout  drop the 12 merged (colliding-ID) chats and recompute reliability (no API calls)"

setup:
	uv sync

export:
	Rscript scripts/export_dialogues.R

check-prespec:
	scripts/check_prespec.sh

holdout:
	scripts/run_holdout.sh

# ---- ratings/ -> output/ (offline, deterministic) ----

outputs: collect reliability

collect:
	$(PY) src/eval_dialogue.py collect --out ratings/holdout --csv output/llm_ratings_holdout_long.csv

reliability:
	$(PY) src/reliability.py --csv output/llm_ratings_holdout_long.csv --out output/reliability_holdout

# ---- Holdout without the 12 chats whose v1 IDs merged a Brussels and a Seville chat ----
# The pre-specified holdout (314) contains all 12; the analysis uses the remaining 302.
colliding:
	Rscript scripts/find_colliding_ids.R

clean-holdout: colliding
	$(PY) src/drop_chats.py --csv output/llm_ratings_holdout_long.csv --drop input/colliding_chat_ids.json --out output/llm_ratings_holdout_clean_long.csv
	$(PY) src/reliability.py --csv output/llm_ratings_holdout_clean_long.csv --out output/reliability_holdout_clean

# NB: the committed output/reliability_dev_v3 tables were computed on the
# haiku vs gpt-4o-mini pair only, before the sonnet/gpt-4o socratic dev runs
# were added; re-running this compares all models and overwrites them.
dev-v3:
	$(PY) src/eval_dialogue.py collect --out ratings/dev_v3 --csv output/llm_ratings_dev_v3_long.csv
	$(PY) src/reliability.py --csv output/llm_ratings_dev_v3_long.csv --out output/reliability_dev_v3

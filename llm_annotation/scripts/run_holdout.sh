#!/usr/bin/env bash
# Pre-specified holdout run (../docs/prespecification.md). 314 chats, 1 pass per rater.
# Resumable: valid ratings already in ratings/holdout are skipped.
set -u
cd "$(dirname "$0")/.."
OUT=ratings/holdout
IDS=input/holdout_ids.json
mkdir -p "$OUT"
# PRESPEC.sha256 was written when the holdout run first started (paths in it are
# the pre-reorganisation ones). Never overwrite it; check the hashes still match.
if [ -f "$OUT/PRESPEC.sha256" ]; then
  scripts/check_prespec.sh || { echo "Pre-specified files changed; aborting." >&2; exit 1; }
else
  shasum -a 256 ../docs/prespecification.md prompts/rate_student.txt prompts/rate_socratic.txt > "$OUT/PRESPEC.sha256"
fi
E="uv run python src/eval_dialogue.py rate --reps 1 --ids-file $IDS --out $OUT"
SD=reasoning_quality,knowledge_building,question_asking,effort_seriousness
SO=identifying_mistake,acknowledging_mistake,supportive_guidance,next_step_guidance,conversational_flow,encouraging_tone
for m in openai:gpt-4o-mini anthropic:claude-haiku-5-5; do
  $E --model $m --prompt prompts/rate_student.txt --dimensions $SD --binary question_asking
  $E --model $m --prompt prompts/rate_student.txt --dimensions $SD --binary question_asking --student-only
done
for m in anthropic:claude-haiku-5-5 openai:gpt-4o; do
  $E --model $m --prompt prompts/rate_socratic.txt --dimensions $SO --optional identifying_mistake,acknowledging_mistake
done
echo ALL_DONE

#!/usr/bin/env bash
# Pre-specified holdout run (docs/prespecification.md). 314 chats, 1 pass per rater.
set -u
OUT=data/llm_ratings
IDS=data/holdout_ids.json
mkdir -p "$OUT"
shasum -a 256 docs/prespecification.md config/prompts/rate_student.txt config/prompts/rate_socratic.txt > "$OUT/PRESPEC.sha256"
E="uv run python scripts/evaluate_chats/eval_dialogue.py rate --reps 1 --ids-file $IDS --out $OUT"
SD=reasoning_quality,knowledge_building,question_asking,effort_seriousness
SO=identifying_mistake,acknowledging_mistake,supportive_guidance,next_step_guidance,conversational_flow,encouraging_tone
for m in openai:gpt-4o-mini anthropic:claude-haiku-5-5; do
  $E --model $m --prompt config/prompts/rate_student.txt --dimensions $SD --binary question_asking
  $E --model $m --prompt config/prompts/rate_student.txt --dimensions $SD --binary question_asking --student-only
done
for m in anthropic:claude-haiku-5-5 openai:gpt-4o; do
  $E --model $m --prompt config/prompts/rate_socratic.txt --dimensions $SO --optional identifying_mistake,acknowledging_mistake
done
echo ALL_DONE

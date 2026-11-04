#!/usr/bin/env bash
# Run the rating panel: rubric variants x models x reps.
# Usage: run_panel.sh OUT_DIR [IDS_FILE]   (omit IDS_FILE for all chats)
# Defaults: one cheap model per provider family, 1 repeat (repeat stability
# was alpha >= .77 on the dev subset), 3 variants. Override with env vars:
#   REPS=3 MODELS="openai:gpt-4o anthropic:claude-sonnet-5-5" VARIANTS="student tutor"
set -u
OUT=${1:?output dir}
IDS=${2:-}
REPS=${REPS:-1}
MODELS=${MODELS:-"openai:gpt-4o-mini anthropic:claude-haiku-5-5"}
VARIANTS=${VARIANTS:-"student student_only socratic"}
P=config/prompts
SD=reasoning_quality,knowledge_building,question_asking,effort_seriousness
TD=accuracy,depth,clarity,learning_outcome,tutor_engagement
SO=identifying_mistake,acknowledging_mistake,supportive_guidance,next_step_guidance,conversational_flow,encouraging_tone

run() { # prompt dims extra...
  local prompt=$1 dims=$2; shift 2
  for m in $MODELS; do
    uv run python scripts/evaluate_chats/eval_dialogue.py rate --model "$m" \
      --prompt "$P/$prompt.txt" --dimensions "$dims" --reps "$REPS" --out "$OUT" \
      ${IDS:+--ids-file "$IDS"} "$@" || echo "FAILED: $prompt $m" >&2
  done
}

for v in $VARIANTS; do
  case $v in
    student)      run rate_student  $SD --binary question_asking ;;
    student_only) run rate_student  $SD --binary question_asking --student-only ;;
    tutor)        run rate_tutor    $TD ;;
    socratic)     run rate_socratic $SO --optional identifying_mistake,acknowledging_mistake ;;
    *) echo "unknown variant $v" >&2 ;;
  esac
done

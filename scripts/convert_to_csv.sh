jq -r '
.[]
  | [
    .dialogue_id,
    .evaluation.dialogue_quality.coherence,
    .evaluation.pedagogical_value.identifying_mistake,
    .evaluation.pedagogical_value.acknowledging_mistake,
    .evaluation.pedagogical_value.supportive_guidance,
    .evaluation.pedagogical_value.next_step_guidance,
    .evaluation.pedagogical_value.conversational_flow,
    .evaluation.pedagogical_value.encouraging_tone,
    .evaluation.pedagogical_value.comments
  ] | @csv
' test.json



jq -r '
  (["dialogue_id","coherence","accuracy","depth","engagement","clarity","learning_outcome","reasoning_quality","question_asking","knowledge_building","effort_seriousness","comments"] | @csv),
  (.[] | [
    .dialogue_id,
    .evaluation.dialogue_quality.coherence,
    .evaluation.pedagogical_value.accuracy,
    .evaluation.pedagogical_value.depth,
    .evaluation.pedagogical_value.engagement,
    .evaluation.pedagogical_value.clarity,
    .evaluation.pedagogical_value.learning_outcome,
    .evaluation.pedagogical_value.reasoning_quality,
    .evaluation.pedagogical_value.question_asking,
    .evaluation.pedagogical_value.knowledge_building,
    .evaluation.pedagogical_value.effort_seriousness,
    .evaluation.pedagogical_value.comments
  ] | @csv)
' "$1"
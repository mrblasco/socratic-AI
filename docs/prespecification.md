# Pre-specification: LLM-rated student behaviour and tutor conduct

Written: 2026-11-03, **before** any holdout chat was rated.
Status of the data at the time of writing: the 40-chat development subset (`data/dev_subset_ids.json`) has been rated and inspected, including treatment-arm means, while developing and tuning the rubrics. The 314 holdout chats (`data/holdout_ids.json`) have not been rated.
The SHA-256 of this file is stored in `data/llm_ratings/PRESPEC.sha256` when the holdout run starts. Commit this file before looking at holdout results.

Context: responds to Reviewer 4, sixth round (conclusions about learner engagement from message counts and from analysis of the AI's strategies only). See `docs/revision_plan.md`.

## 1. Data
- Unit: one student-AI chat (354 analysable chats from 122 students; 358 raw chats minus 4 from the test user, `user_id == 1`). Students contribute 1-7 chats.
- **Primary analysis sample: the 314 holdout chats.** The 40 development chats were used to write and tune the anchors, so they are excluded from the primary analysis and included only in a sensitivity analysis (all 354).
- Arms: Socratic vs non-Socratic AI agent (`treatment_tutor_id`); school (`location`).

## 2. Rating instruments (frozen)
Prompts as of the commit that contains this file: `config/prompts/rate_student.txt`, `config/prompts/rate_socratic.txt`. Any later change is a deviation (section 8).

| Rubric | Items | Raters (one pass each, temperature 0 or provider default) |
|---|---|---|
| Student behaviour | `reasoning_quality`, `knowledge_building`, `effort_seriousness` (1-5); `question_asking` (0/1) | `openai:gpt-4o-mini`, `anthropic:claude-haiku-5-5` |
| Socratic conduct (tutor) | `supportive_guidance`, `next_step_guidance`, `encouraging_tone`, `conversational_flow` (1-5) | `anthropic:claude-haiku-5-5`, `openai:gpt-4o` |

- `identifying_mistake` and `acknowledging_mistake` are rated but treated as exploratory only (null in ~70% of ratings in development; models disagree on direction).
- Student rubric is run in two modes: **full dialogue** (primary) and **student turns only** (sensitivity; blind to the tutor's style).
- Model IDs, prompt hash, git commit and timestamps are stored in each run's `manifest.json` and per-chat JSON.

## 3. Reliability criteria (decided in advance)
For each item, on the holdout:
- Ordinal items: Krippendorff's alpha (ordinal) between the two raters >= 0.67 counts as acceptable. Rank (Spearman) correlation is reported alongside, because the two model families differ in leniency.
- Binary item (`question_asking`): percent agreement >= 80% and Gwet's AC1 >= 0.60.
- Items that miss the threshold are reported as **exploratory** and are not used for headline claims.
- Repeat stability was established in development (alpha 0.77-1.00); no repeats on the holdout.

## 4. Outcomes
**Primary family A (student behaviour, from the student rubric):** `reasoning_quality`, `knowledge_building`, `effort_seriousness`, `question_asking`.
**Primary family B (manipulation check, Socratic rubric):** `supportive_guidance`, `next_step_guidance`, `encouraging_tone`, `conversational_flow`.
No other LLM-rated item is a primary outcome.

Item score for analysis: the mean of the two raters' scores after standardising each rater's scores within the rubric (z-score over all rated chats), so leniency differences do not enter. For `question_asking`: the proportion of raters scoring 1 (0, 0.5, 1) analysed as ordinal.

## 5. Models
- Cumulative-link mixed model (`ordinal::clmm`): outcome ~ arm + school + (1 | student). For the standardised mean score, a linear mixed model (`lme4::lmer`) with the same structure is the primary specification; the cumulative-link model on each rater's raw score is the robustness check.
- **Primary specification adjusts for log(number of student messages) and log(1 + student words) in the chat.** The unadjusted model is reported next to it, with the statement that the unadjusted contrast is partly mechanical because the Socratic prompt requires replies.
- Task: included as a fixed effect if a task identifier can be recovered from the experiment logs; otherwise chat order within student is used as a proxy and flagged as such.
- Effect sizes: standardised coefficient with 95% CI (cluster-robust or mixed-model).

## 6. Inference
- Two-sided tests, alpha = 0.05. Benjamini-Hochberg correction within each primary family (A: 4 tests; B: 4 tests).
- Claims are made on the adjusted full-dialogue model. A result is described as robust only if the student-only mode gives the same sign and a CI that excludes zero, or (if not significant) a point estimate within the CI of the primary.
- If an item fails the section 3 criteria it is excluded from the headline and reported as exploratory.

## 7. Sensitivity analyses (all pre-specified)
1. Student-only ratings instead of full dialogue.
2. Each rater separately (no averaging).
3. Truncate every chat to its first 3 student messages (equalises exposure across arms).
4. Exclude chats with one student message.
5. All 354 chats (adds the development subset).
6. Compare with a length-only model: does the rating add information beyond message and word counts (change in model fit)?

## 8. Deviations
Any departure from this document after the holdout run starts is recorded below with date and reason, and listed in the paper's supplement.

- (none yet)

## 9. Interpretation commitments
- Results are described as *observable reasoning and effort in the chat transcript, as rated by LLMs*, not as learner engagement, learning or cognition.
- LLM agreement shows consistency, not validity. This is stated as a limitation (no human validation, no budget).
- The paper does not infer learning benefits from these ratings; learning is addressed only with Task 3 correctness.

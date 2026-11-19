# Changes: aligning research questions between intro and methods

## Problem

The intro stated four RQs, while the methods said "five research questions (RQ1–RQ5)" and used a different mapping:

| Intro (before) | Methods (before) |
|---|---|
| RQ1 explanations → estimation performance | H1 (RQ1). Matched. |
| RQ2 explanations → perceived AI accuracy | H2 (RQ2). Matched. |
| RQ3 Socratic → learning, engagement, confidence | H3a learning, H3b confidence, H3c helpfulness |
| RQ4 Socratic → perceived helpfulness | H4a/H4b interaction volume and observable reasoning |
| (none) | RQ5: H5, H5a, H5b |

Related issues: H5 and H5a overlapped; "engagement" in RQ3 conflicted with the methods' stance that message counts are not engagement; heterogeneity (H5b) had no stated test; H3a "learning outcomes" is only measurable in Task 3.

## Final mapping

- **RQ1, RQ2**: unchanged.
- **RQ3**: learning outcomes and confidence (H3a, H3b).
- **RQ4**: perceived helpfulness (H4, formerly H3c).
- **RQ5**: content of student–AI conversations:
  - H5a: interaction volume (formerly H4a)
  - H5b: observable student reasoning and effort (formerly H4b)
  - H5c: Socratic conduct / manipulation check (formerly H5, with H5a pedagogical quality folded in)
- **Heterogeneous effects** (formerly H5b): now an unnumbered exploratory analysis using condition-by-covariate interactions (prior ChatGPT experience, gender, school, task).

## Edits

### sections/01-intro.Rmd
- RQ3 now reads "learning outcomes and confidence" (removed "engagement").
- Added a paragraph and RQ5 after RQ4, explaining why the conversations themselves are analysed (the Socratic prompt mechanically raises message counts; the manipulation needs checking).
- RQ4 lead-in changed from "our last research question" to "our fourth".
- Fixed typos: "whily" → "while", "groupd" → "group".

### sections/02-methods.Rmd
- Hypotheses restructured as above; "five research questions" now says "stated in the Introduction".
- H3a specifies Task 3 only (post-AI correctness and the no-AI follow-up).
- H4 (helpfulness) is written as two-sided: an increase was expected, but habits with direct-answer chatbots could reverse it.
- Fixed "RQ-1/RQ-3" cross-references (now RQ1, RQ3 and RQ4).
- Deleted a stale commented-out "Student-AI Interaction Metrics" block.

### sections/03-results.Rmd
- Confidence label RQ4 → RQ3.
- Helpfulness label RQ5 → RQ4.

## Open items

- sections/04-discussion.Rmd line 25 says "despite a greater engagement", which contradicts the methods' stance on message counts. Reword.
- No results subsection or discussion paragraph yet carries the RQ5 / H5a–c labels. Check the LLM-coded results section exists and is numbered consistently.
- The abstract has no RQ labels, so nothing changed there.
- Confirm the "pre-specified" thresholds and the exploratory heterogeneity wording match the actual protocol (see docs/prespecification.md).
- Not yet knitted; changes are unrendered.

---

# Results section rewritten from `steps/` (branch rev/results-from-steps)

`sections/03-results.Rmd` no longer estimates anything. Every number is read from `output/tables/*.csv` written by `Rscript analysis.R`.
Structure: sample and randomisation; Experiment 1 (RQ1, RQ2); Experiment 2 (RQ3 confidence and learning, RQ4 helpfulness, RQ5 conversations); exploratory analyses.

## Changes to the pipeline
- `steps/07_reasoning.R`: now also saves `reasoning_effects.csv` (HC3 effects of the explanation arm). The models existed but were never saved.
- `steps/10_perceived_accuracy.R` (new): RQ2 had no script. Saves `perceived_accuracy_descriptives.csv` and `perceived_accuracy_effects.csv`.
- `steps/08_llm_ratings.R`: adds `tab_llm_volume_tests.csv` (H5a: Wilcoxon and mixed model on student messages and words, all 354 chats).
- `steps/09_sample_characteristics.R`: excluded the test account (`student_id == 1`), which had been counted in the Sample Characteristics table and the attitudes figure (122 -> 121 students).
- `sections/90-supporting.Rmd`: the regression section described a mixed ordinal model that was never used; replaced by a description of the models in `steps/`.

## Substantive changes in what the Results say
| Topic | Old text | New text (from `steps/`) |
|---|---|---|
| Sample | 122 students | 121 students (one test account excluded), 120 with complete primary outcomes |
| RQ1 accuracy | Explanation "significantly" reduced median dollar error (bootstrap, one-sided, outlier removed) | No effect on mean absolute log error (0.2 points, 95% CI -17.5 to 17.8) |
| RQ1 anchoring | not tested | Explanation cut the share ending within 10% of the AI estimate by 20.6 pp (p = 0.01) |
| RQ2 | Human rating effect "significant" | Borderline (adjusted OR 1.95, p = 0.047; unadjusted p = 0.11); exploratory |
| RQ3 confidence | Fisher/ordinal pooled, no clustering | Per-task models, Holm, randomisation inference, MDE (about 0.5 SD); all null |
| RQ3 learning | No test of Socratic effect on follow-up question | Task 3 correctness null (+0.9 pp, CI -14.8 to 16.7); retention coding of "gold" flagged as uncertain (18% vs 36% correct) |
| RQ4 helpfulness | Pooled Fisher p = 0.025; "13 pp" | Task 1 clearly lower (-0.60 points, Holm 0.017); Task 3 weaker; Task 2 null; scale-alignment checks |
| RQ5 volume | 20 vs 8 messages per student | Median 3 vs 1 student messages per conversation, with tests |
| RQ5 legacy figure | Single-rater clarity/depth/engagement figure | Removed |
| New | | Task 2 opinion change (Socratic 48% vs 31% changed), exploratory |

## Open issues found while doing this
- Discussion and abstract still say AI explanations "significantly improved performance" and Socratic AI "fostered significantly greater engagement"; the first is not supported by the pipeline, the second contradicts the methods.
- Discussion mentions "less clear / less deep" Socratic AI from the legacy single-rater coding.
- Intro, abstract and highlights say N = 122; the analysis has 121 (120 for Experiment 2).
- Conversation logs have 86 user accounts (Brussels: 31 accounts for 63 students) and 19 accounts appear in both arms: `user_id` is not a reliable student identifier.
- The transfer question (`q29_sound_speed_verify`) uses different codes in each school; which code is "gold" is unverified.
- Methods describe student-clustered models for H3/H4; the pipeline estimates per-task models (one row per student), plus a pooled clustered model.
- Planned heterogeneity by ChatGPT experience and gender is not in `steps/`.
- Step 07 keeps the 6,969 outlier (log scale); the old text removed it.

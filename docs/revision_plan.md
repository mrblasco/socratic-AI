# Revision plan: sixth round (Reviewer 4)

Scope: revise within the existing study, data and research questions (see `submissions/01_HSSC/2026-08-sixth-round/appeal.md`). No rewrite around Experiment 2.
Source comments: `submissions/01_HSSC/2026-08-sixth-round/editor_reviewers.md`.
Manuscript files: `manuscript/*.Rmd`.

---

## Part A. What the reviewer asked

Status key: **Doable** = text/analysis edit only; **Mitigate** = cannot be fixed, disclose and argue.

### A1. RQs, hypotheses, theory: Doable
- [ ] Make RQs consistent. `01-intro.Rmd` defines RQ1-RQ4; `02-methods.Rmd:122` and H5a/H5b use RQ1-RQ5; `03-results.Rmd:826` calls helpfulness RQ5 (intro: RQ4). Decide: add RQ5 (pedagogical quality / heterogeneity) to the intro, or fold H5 into RQ3/RQ4. Renumber everywhere (methods, results, discussion, abstract). Cf. docs/tasks.md Task 3.
- [ ] Add a "Key constructs" paragraph to `02-literature.Rmd` with citations: critical thinking (currently an uncited footnote, `02-methods.Rmd:10`), perceived helpfulness, confidence, cognitive engagement (ICAP / Chi & Wylie is the obvious frame), Socratic vs solution-providing guidance.
- [ ] Link each RQ to a literature subsection (one sentence each).
- [ ] Optional: move the hypotheses to the end of the intro/literature.

### A2. Methods gaps: Doable
- [ ] Add a table of key variables: name, scale, timing, task, RQ.
- [ ] Task 3: describe the item format (MC, number of options, coding, pre/post and follow-up item).
- [ ] Add an "Analysis" subsection justifying each test: Wilcoxon / Mann-Whitney (ordinal 5-pt items), bootstrap of medians (skewed error), ordinal logit, mixed models (students contribute 1-7 chats).
- [ ] Describe the LLM-based Socratic-dimension and cognitive-engagement ratings in Methods, not first in Results (full protocol in Part B).

### A3. "Guess" vs "estimate" wording: Mitigate
- [ ] Use "guess" consistently to match the instrument (`99-questionnaire.Rmd`); remove "estimate" where it describes what students were asked.
- [ ] Add a limitation: the wording may shape cognitive processes; the treatment contrast is unaffected since both arms saw identical wording; generalisation to estimation tasks is limited.

### A4. Analyses and conclusions
- [ ] `03-results.Rmd:830`: delete "stronger for Task 1 and Task 3 than Task 2" (pooled p = .025, per-task p >= .095). Optionally test a treatment x task interaction and report it as exploratory.
- [ ] `04-discussion.Rmd:13, 25`: replace "more beneficial than self-generation-based learning" with "than receiving the AI's answer without an explanation"; remove self-explanation framing (control arm was never asked to self-explain).
- [ ] Engagement: rename message/word counts "interaction volume"; state they are partly mechanical under the Socratic prompt; drop "despite a greater engagement" (`04-discussion.Rmd:25`). Replace learner-engagement claims with the student-side rating results from Part B, length-adjusted.
- [ ] Likert items: lead with medians / ordinal-model effects; percentages are descriptive only.

### A5. Response to reviewer
- [ ] Point-by-point reply, one paragraph per numbered comment, with line references to the revised text; state plainly what could not be changed (A3, and the Experiment-2 rewrite).
- [ ] Track-changes PDF via `scripts/create_diff.sh`.

---

## Part B. Other improvements to raise acceptance odds

Priority: re-run the LLM evaluation to a standard a sceptical reviewer cannot dismiss. The current ratings (`data/cognitive_engagement.csv`) have these problems:
single `gpt-4o` pass, no reliability check, rater sees the tutor's turns (not blind to condition), student scores mechanically tied to message count (rho 0.5-0.6), floor effects (60-70% score 1), 15 failed ratings (5 non-Socratic, 10 Socratic), and chat counts that disagree (354 rated, 358 raw, 362 in the text).

### B1. Fix the data pipeline first
- [x] Reconcile the chat counts: raw 358 = 354 analysed + 4 test-user chats (`user_id == 1`). The manuscript's "362" (`03-results.Rmd:588`, `:677`) has no source: change to 354 (text edit still to do).
- [x] (done; smoke-tested with OpenAI and Anthropic) Fix `scripts/evaluate_chats/eval_dialogue.py`: default prompt path points to `analysis/prompts/` but prompts live in `config/prompts/`; use structured output (JSON schema) instead of `json.loads` on free text; retry with backoff on parse failure; log raw outputs and API/model version; fix the hard-coded `Path` default.
- [x] Save every raw response to disk (`data/llm_ratings/<run_id>/<chat_id>.json`) with a manifest: model ID, date, temperature, prompt hash, git commit.
- [~] Fix `R/dialog2.R` (`fa_results` typo fixed; left join to `ds_socratic` pulls in unrelated columns).

### B2. Redesign what is rated (construct validity)
- [ ] Separate the two units: **tutor-side** (accuracy, depth, clarity, ...) and **student-side** (reasoning, question-asking, knowledge building, effort). Run them in separate prompts.
- [ ] **Student-side rating sees student turns only** (with minimal context, e.g. the task statement and the tutor's immediately preceding turn, or none). Tests the blinding and "credit for elicited replies" concern. Run both variants and report both.
- [ ] Anchor scales with behavioural definitions and examples; consider coding observable behaviours (binary or counted: gives justification, asks a question, builds on previous turn, attempts a calculation) instead of 1-5 impressions. This reduces floor effects and fits ICAP (passive / active / constructive / interactive).
- [ ] Keep the "engagement" tutor-side item out of the learner-engagement claims; relabel it "tutor-elicited engagement".
- [ ] Pre-specify the primary outcomes (e.g. reasoning, knowledge building, effort) and the analysis model before re-running; write this down in `docs/` with a date and commit it.

### B3. Reliability and validation (no budget for human coding)
Human validation is out of scope. Replace it with a multi-rater LLM design, and state this openly as a limitation (LLM agreement shows consistency, not validity).
- [ ] **Rater panel**: 3-4 LLMs from different families/providers (e.g. one Claude, one GPT, one Gemini, one open-weight model), same prompt, same structured-output schema, temperature 0 (or lowest available). Pin exact model IDs and run dates.
- [ ] **Inter-rater reliability across models**: Krippendorff's alpha (ordinal) and weighted Cohen's kappa for each dimension, plus ICC(2,k) for the panel mean. Report per dimension and per arm. Pre-specify a threshold (e.g. alpha >= .67 acceptable, >= .80 good); dimensions below it are demoted to exploratory or dropped.
- [ ] **Intra-rater stability**: 3 repeat runs per model per chat; report alpha across runs. Low stability at temperature 0 flags an unreliable item.
- [ ] **Aggregate score**: use the panel median (or mean) as the outcome; also report each model's own result as a sensitivity analysis, to show the treatment effect does not depend on one rater.
- [ ] **Disagreement audit**: read ~20 chats with the largest between-model disagreement and document the cause (rubric ambiguity vs model bias); refine the rubric on a *development* subset (e.g. 40 chats), then freeze it and rate the remaining chats. This avoids tuning to the test data.
- [ ] **Bias checks** (cheap proxies for human validation): re-rate student-only turns (blinding); shuffle dimension order; compare to a trivial baseline (message/word count alone) and report incremental information beyond length.
- [ ] **Convergent validity with existing data**: correlate panel scores with independent signals, e.g. the earlier Socratic-rubric scores (`dialogues_socratic_eval.csv`), student-reported confidence and helpfulness, and Task 3 correctness. Weak but expected correlations support construct validity.
- [ ] Report the prompts verbatim, model IDs, dates, and full agreement tables in the supplement; archive raw responses.
- [ ] Limitations text: LLM raters share training-data biases, may favour fluent or Socratic-styled text, and agreement among them is not ground truth.

### B4. Analysis of the re-run ratings
- [ ] Primary model: ordinal mixed model (`ordinal::clmm` / `brms` cumulative logit) with treatment, school, task, and a random intercept for student; for binary behaviour codes, a logistic mixed model.
- [ ] **Always adjust for log student-message count and log words** as the main specification, with the unadjusted model shown for comparison. State that without adjustment the effect is partly mechanical.
- [ ] Sensitivity: student-turns-only ratings; first-N-turns truncation (equalise exposure across arms); exclude chats with a single student message.
- [ ] Multiple testing: BH correction across the pre-specified dimensions; separate "primary" from "exploratory".
- [ ] Do not read means on floor-bound scales as effect sizes; report proportions above the floor.
- [ ] Cluster the p-values (students have several chats); the Wilcoxon p-values used above are naive.
- [ ] Report the missing-ratings fix and show that the results do not depend on which chats failed.

### B5. Framing and reporting
- [ ] Describe the result as "observable reasoning in the chat transcript", not learner engagement or learning; state that it is LLM-rated and give the validation numbers.
- [ ] Tie the result to the existing finding that the Socratic AI was rated less clear and less deep, and to the lower perceived helpfulness.
- [ ] Add a limitations paragraph: LLM rater, transcript-only evidence, mechanical dependence on forced turns, no behavioural learning gain from the Socratic arm.

### B6. Other publication-readiness items
- [ ] Reproducibility: pin dependencies (`pyproject.toml` is empty and requires Python >= 3.14; `requirements.txt`/`uv.lock` disagree), make `make` build from clean, and archive the code + data with a DOI (Zenodo/OSF) for the Data Availability statement.
- [ ] Data protection: confirm the student chat logs are de-identified before sharing (`analysis/data/processed/*.rds` are tracked).
- [ ] Terminology audit (docs/tasks.md Task 2): tutor -> agent; style -> guidance; direct instruction -> solution-providing support.
- [ ] Git hygiene (separate from this plan): adopt the `.gitignore` clean-up on this branch.

---

## Suggested order
1. A1, A4 text fixes (cheap, high value for the response letter).
2. B1 pipeline fixes, then B2 rubric design and pre-specification.
3. B3 multi-LLM panel: develop/freeze the rubric on a dev subset, then run all models with repeats.
4. B4 analysis, then write A2 Methods and B5 text from the results.
5. A5 response letter and diff.

---

## Update 2026-11-03: cost-reduced rating design

Original full design (4 variants x 2 large models x 3 reps, ~8,500 calls) was judged too expensive (~$70, unverified prices). Dev-subset evidence (40 chats, 20 per arm, `data/dev_subset_ids.json`):
- Repeat stability is high for all four models tried (alpha 0.77-1.00), so 1 rep per model suffices on the full data.
- Small models track their larger siblings (haiku~sonnet 0.68, gpt-4o-mini~gpt-4o 0.63); cross-family agreement is lower (~0.45): provider-specific leniency, esp. on effort (GPT +0.5).

New default (`scripts/evaluate_chats/run_panel.sh`): models `openai:gpt-4o-mini` + `anthropic:claude-haiku-5-5`, 1 rep, variants `student`, `student_only`, `socratic`. The general `rate_tutor` rubric is dropped from the default (run with `VARIANTS=tutor` if wanted). Estimated cost for all 354 chats: ~$0.1/variant (mini), ~$1.3/variant (haiku; assumes $1/$5 per M tokens, unverified), i.e. roughly $4-5 total.

Rubric development (dev subset, mini vs haiku, alpha): effort 0.07 -> 0.69 after tightening anchors (pasted task statement is not student-authored; one-word replies = 2). Still weak: `question_asking` (0.13-0.38; ~70% of ratings at the floor). v2 numbers are optimistic because anchors were tuned on the same 40 chats; the other 314 chats are the holdout.

Open before the full run: decide what to do with `question_asking` (merge with another item, make it binary "asked a content question", or report as exploratory); run Socratic rubric on the dev subset; write the dated pre-specification.

### Dev results, round 3 (2026-11-03; gpt-4o-mini vs claude-haiku-5-5, 40 chats, 2 reps; `data/llm_ratings_dev_v3/`, `data/reliability_dev_v3/`)
- `question_asking` is now binary (0/1; `--binary`). Repeat alpha 0.81-1.00; between-model alpha 0.33 but prevalence is only 10-30%, so alpha is unstable; mean abs diff 0.22 (~78% raw agreement). Report percent agreement and Gwet's AC1 alongside alpha for this item.
- Other student items between-model alpha: effort 0.64, knowledge building 0.75, reasoning 0.66 (threshold .67). Socratic arm higher on all four for both models.
- Socratic rubric FAILS between-model agreement (alpha -0.5 to -0.06) although each model is internally stable (repeat alpha 0.70-1.00). gpt-4o-mini is lenient/non-discriminating (supportive_guidance 3.6 vs 4.2 non-Socratic vs Socratic), haiku discriminates strongly (1.1 vs 2.7). The two mistake items are null in 52-85% of ratings and models disagree on which chats contain a mistake. Do not run this rubric on the full data with mini as is.

### Socratic rubric with four raters (dev subset, 2 reps)
- Within-family agreement is high (haiku~sonnet alpha 0.67-0.87 on all six items), so haiku is an adequate cheap stand-in for sonnet. gpt-4o-mini is the outlier (alpha <= 0.5, mostly negative with the others; attenuated arm effect on the guidance items: +0.5-0.6 vs +1.4-1.8 for haiku/sonnet/gpt-4o) and is dropped for this rubric.
- Cross-family alpha is lower (haiku~gpt-4o 0.32-0.57 on guidance/mistake items). Levels differ (GPT scores ~1 point higher; encouraging_tone alpha is negative because of this offset) while the direction and size of the Socratic-vs-non-Socratic difference agree on supportive_guidance, next_step_guidance and encouraging_tone. Report rank correlations / per-model standardised effects alongside alpha.
- The mistake items are null in ~70% of ratings across all models (about 12 chats) and the models disagree on direction: drop or demote to exploratory.

### Holdout results (2026-11-03; `notebooks/effect_analysis.Rmd` -> `.html`)
- Reliability gate (alpha >= .67 applied to unrounded values): primary = reasoning_quality (.70), knowledge_building (.81). Exploratory = effort_seriousness (.6695, misses by .0005), question_asking (agree 74%), all Socratic items (alpha -.20 to .56).
- Adjusted (for message/word counts) Socratic-minus-non-Socratic effects: reasoning +0.29 SD [.12,.46], BH p=.002; knowledge building +0.17 [.01,.33], BH p=.0496 (not significant for the Claude rater alone). Unadjusted effects are 2.5-4x larger (+0.74 to +0.82), i.e. mostly driven by the number of student messages.
- Length (messages + words) alone explains 51-64% of the variance in the student items (marginal R2).
- Sensitivity 3 (truncate to first 3 student messages) still to do; requires re-rating.

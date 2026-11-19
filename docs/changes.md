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

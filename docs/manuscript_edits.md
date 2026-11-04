# Proposed manuscript edits: LLM-based coding of dialogues

For manual review and integration. Nothing here has been applied to `manuscript/`.
Source of every number: `analysis.R` (outputs in `output/`, file map in Section 4b), which reproduces `notebooks/effect_analysis.Rmd` (holdout ratings, `data/llm_ratings_long.csv`, reliability in `data/reliability_holdout/`). Pre-specification: `docs/prespecification.md`.

Each edit gives: **where** (file and current text), **action** (replace / insert / delete), then the **proposed text**. Text in `[BRACKETS]` needs your decision or a fact only you can confirm.

---

## 0. Read first: things to confirm before integrating

1. **Chat counts disagree.** `03-results.Rmd:588` says 362 conversations (366 chats minus 4). The data contain 358 raw chats; 4 belong to the test user (`user_id == 1`), leaving **354 analysable chats from 86 students**. The ratings were run on these 354 (314 holdout + 40 development). Also `122 participants x 3 tasks = 366` does not match 86 students with chats. [CONFIRM: why 36 participants have no chat (e.g. experiment 1 only) and why 12 expected chats are absent.] The edits below use 354/86; fix the footnote at `03-results.Rmd:588` accordingly.
2. **Units differ from the current text.** The current Results report medians per student (20 vs 8 messages) while the new analysis works per chat (median student messages per chat: 1 vs 3). I use per-chat units for the new results and label them. Keep or reconcile with the existing per-student figures.
3. **AI-agent quality items from the old rating (clarity, depth, "engagement")** are not re-estimated under the new panel (we dropped the general `rate_tutor` rubric for cost). The edits keep the old clarity/depth finding only as a clearly labelled single-rater result. [DECISION: keep as single-rater exploratory, drop, or run `VARIANTS=tutor` with the new pipeline (~$3).]
4. **H5b (heterogeneous effects by gender, ChatGPT experience, task) has not been tested** by the new analysis. [DECISION: drop H5b, or run treatment x covariate interactions; the edits below delete it.]
5. **Honesty about timing.** The rating protocol and analysis plan were written after data collection and after the 40 development chats had been rated and inspected, but before the 314 holdout chats were rated. The text says this explicitly. Commit `docs/prespecification.md`, `data/holdout_ids.json` and the prompts to git (and, ideally, archive with a DOI) so the date can be verified.
6. **Effect sizes are in standardised units**: each rater's scores are z-scored, then the two raters' z-scores are averaged. The average of two imperfectly correlated z-scores has SD below 1, so the coefficients slightly overstate effects relative to the SD of the averaged score. Say "standardised units", not "SD".
7. **Missing references to add to `refs.bib`**: Chi & Wylie (2014, ICAP, *Educational Psychologist* 49(4)); Zheng et al. (2023, "Judging LLM-as-a-judge with MT-Bench and Chatbot Arena", NeurIPS); Krippendorff (2011, "Computing Krippendorff's alpha-reliability"); Gwet (2008, *Br J Math Stat Psychol* 61); Benjamini & Hochberg (1995, *JRSS B* 57). Keys below are placeholders.
8. **Task identifier** is not in the chat logs. The models use chat order within student as a proxy for task. [If a task variable can be recovered from the experiment logs, re-run the notebook with it.]

---

## 1. Methods (`manuscript/02-methods.Rmd`)

### 1.1 Replace the subsection "Student-AI Interaction Metrics" (currently lines ~116-118)

**Action:** replace the whole subsection with the two subsections below.

```markdown
### Interaction volume

For each AI-student conversation (one per task and student) we recorded the number of student messages and the number of words the student wrote. These counts describe how much a student interacted with the agent. They do not measure the quality of the interaction, and they are partly determined by the experimental condition: the Socratic agent was instructed to respond with questions, which invites more replies. We therefore do not interpret message counts as engagement, and we adjust for them when comparing the observable content of the conversations (next subsection).
```

### 1.2 Insert a new subsection after 1.1: LLM-based coding of the dialogues

```markdown
### Coding of the dialogues with large language models {#sec:llm-coding}

To address what students and the AI agent did in the conversations, beyond how many messages they exchanged, we coded every conversation with large language models (LLMs) used as raters [@zheng2023judging]. The dialogue was shown to the model with a written rubric, and the model returned an integer score for each item in a fixed JSON format. We coded two sets of items.

*Student behaviour.* Four items describe what the student wrote: reasoning quality (does the student give reasons or steps of their own), knowledge building (does the student use, extend or test what was said earlier), effort and task focus, and whether the student asked at least one question about the content of the task. The first three were scored 1-5 and the fourth 0/1. Each score level is defined by observable behaviour in the student's own messages (for example, a score of 2 on reasoning means one stated step with no justification). Raters were told to credit only student-authored content, not the pasted task statement, not ideas that only the AI agent stated, and not the number of turns. The items are inspired by the ICAP view of learner activity [@chi2014icap], but they measure what is visible in the transcript, not cognition.

*AI-agent conduct.* Six items adapted from the rubric of Pauzi et al. [@pauzi2025automating] describe the agent's behaviour: identifying the student's mistake, acknowledging it, supportive guidance without giving the answer, next-step guidance, conversational flow and encouraging tone, each on a 1-5 scale with behavioural anchors. The two mistake items apply only when the student made a mistake and were otherwise left empty. Four items (supportive guidance, next-step guidance, encouraging tone, conversational flow) are used as a check that the Socratic manipulation worked; the two mistake items are reported as exploratory.

*Raters and procedure.* Each rubric was applied by two LLMs from different providers: GPT-4o-mini and Claude Haiku 5.5 for the student items, and Claude Haiku 5.5 and GPT-4o for the AI-agent items. [Exact versions in Appendix \@ref(sec:si-llm-protocol).] Each model rated each conversation once. Student items were rated twice, once with the full dialogue and once with only the student's messages, so that the rater could not see the agent's style. All responses were stored with the model version and prompt.

*Development and holdout.* We wrote and refined the rubrics on a random subset of 40 conversations (20 per condition). During this phase we examined agreement between raters and the difference between conditions, and tightened ambiguous score definitions. The rubrics were then frozen and applied to the remaining 314 conversations (the *holdout* sample). The rating protocol and analysis plan were written after data collection and before the holdout conversations were rated, and are archived with the code [@REPO-OR-DOI]. Primary results use the holdout sample; the 40 development conversations are included only in a sensitivity analysis.

*Reliability.* We pre-specified that an item is treated as a primary outcome only if the two raters agree sufficiently on the holdout sample: Krippendorff's alpha (ordinal) of at least 0.67 for 1-5 items [@krippendorff2011alpha], and percent agreement of at least 80% together with Gwet's AC1 of at least 0.60 for the yes/no item [@gwet2008]. Items below these thresholds are reported as exploratory. Agreement among LLM raters shows that the coding is consistent; it does not show that it is valid. We did not have human coders.
```

### 1.3 Replace hypotheses H4 and H5 (currently lines ~147-158) and the sentence that closes them

**Action:** replace from `<!-- RQ4 ... -->` through the paragraph "These hypotheses are tested using mixed-effects regressions on LLM-coded rubric scores...". [Renumber RQs in the Introduction accordingly; see item 2 in `docs/revision_plan.md`.]

```markdown
**H4a (RQ4: Interaction volume).**
We hypothesise that Socratic AI leads students to send more messages than non-Socratic AI. This is tested with non-parametric comparisons of the number of student messages and words per conversation. Because the Socratic agent was instructed to reply with questions, this difference partly follows from the condition, and we do not treat it as evidence of engagement.

**H4b (RQ4: Observable student reasoning and effort).**
We hypothesise that, in conversations with the Socratic agent, students show more observable reasoning, knowledge building, effort and content questions than students with the non-Socratic agent, over and above the greater number and length of their messages. This is tested with linear mixed models of LLM-coded scores (see \@ref(sec:analysis-llm)).

**H5 (RQ5: AI-agent conduct, manipulation check).**
We hypothesise that the Socratic agent scores higher than the non-Socratic agent on supportive guidance, next-step guidance, encouraging tone and conversational flow, as coded by LLM raters.
```

[If H5b is dropped, also delete the final sentence of the hypotheses block that mentions "interaction terms between treatment and covariates".]

### 1.4 Insert a new analysis subsection (after the hypotheses; also answers Reviewer 4, point 2)

```markdown
### Statistical analysis of the coded dialogues {#sec:analysis-llm}

For each item, each rater's scores were standardised (z-scores over all rated conversations) and the two raters' standardised scores were averaged; the yes/no item was averaged as 0, 0.5 or 1. We estimated linear mixed models of the item score with a random intercept for student, since students contributed one to seven conversations and the condition varied within some students, and fixed effects for condition, school and the order of the conversation within the student (a proxy for task, because no task identifier is stored in the logs). The primary specification also adjusts for the logarithm of the number of student messages and of the number of student words, because these differ strongly between conditions. We also report the model without this adjustment, which mixes the effect of the agent on what students did with the mechanical effect of the condition on how much they typed. Coefficients are reported as differences between the Socratic and non-Socratic conditions in standardised units with 95% confidence intervals. We corrected for multiple testing with the Benjamini-Hochberg procedure [@benjamini1995] within each family of four items (student behaviour; AI-agent conduct).

We used non-parametric tests (Wilcoxon rank-sum) for the number of messages and words, which are strongly right-skewed, and linear mixed models for the standardised averages of ordinal ratings. [To reconsider: cumulative-link models on each rater's raw scores are a straightforward robustness check, and ordinal mixed models are an alternative primary analysis.] Sensitivity analyses: (i) ratings made on student messages only; (ii) each rater analysed separately; (iii) excluding conversations in which the student sent a single message; (iv) including the 40 development conversations; and (v) comparing how much of the variation in each score is accounted for by message and word counts alone.
```

---

## 2. Results (`manuscript/03-results.Rmd`)

### 2.1 Section "Student-AI Interactions" (line ~430): change the conclusion

**Where:** the last sentence of the first paragraph: "This evidence supports the hypothesis that the Socratic tutor encouraged more engagement and interaction, resembling a relatively more genuine student-tutor talk."

**Action:** replace with:

```markdown
Socratic students therefore interacted more with the agent. Because the Socratic agent was instructed to answer with questions, part of this difference follows from the condition itself, and message counts alone do not show that students were more engaged or thought harder. We examine the content of the conversations next.
```

[Optional addition, per-chat numbers for the coded sample: "In the 314 conversations analysed below, the median number of student messages was 3 in the Socratic condition and 1 in the non-Socratic condition (26 and 13 words); 27% of Socratic and 68% of non-Socratic conversations contained a single student message."]

### 2.2 Replace the section "Automatic evaluation of Socratic dimensions" (lines ~584-595)

**Action:** replace the heading and the three paragraphs before the `socratic-eval` chunk. Regenerate or drop `Figure \@ref(fig:socratic-dimensions)` (it uses the old single-rater scores) and replace it with Table 1 below. Optional figure: `output/figures/fig_llm_effects.pdf` (forest plot, unadjusted vs adjusted). See Section 4b for the full file map.

```markdown
### What the conversations show: AI-agent conduct and observable student behaviour {#sec:llm-results}

We coded the conversations as described in Section \@ref(sec:llm-coding). The 40 development conversations are excluded here; the results below are based on the 314 holdout conversations from 85 students (161 non-Socratic, 153 Socratic), and Appendix \@ref(sec:si-llm-protocol) reports the all-conversations results.

*Agreement between raters.* Of the four student-behaviour items, reasoning quality (alpha = 0.70) and knowledge building (0.81) met the pre-specified reliability threshold and are our primary outcomes. Effort and task focus fell just short (alpha = 0.669; threshold 0.67), and the yes/no question item reached 74% agreement (threshold 80%), because the two raters disagreed on how often students asked questions (13% vs 25% of conversations). We report both as exploratory. None of the four AI-agent-conduct items reached the threshold (alpha between -0.20 and 0.56). The raters differed in leniency (the GPT model gave higher scores than the Claude model), but ranked conversations similarly (rank correlations 0.55-0.70), so we report the AI-agent-conduct results as exploratory.

*AI-agent conduct.* The Socratic agent was rated clearly higher on supportive guidance without giving the answer (+1.45 standardised units, 95% CI 1.30 to 1.61), next-step guidance (+1.41, 1.25 to 1.56) and encouraging tone (+1.09, 0.92 to 1.27), and the two raters agreed on the direction and approximate size of these differences (Appendix Table \@ref(tab:si-per-rater)). Conversational flow was rated higher after adjusting for message counts (+0.36, 0.14 to 0.58) but not before (-0.11, -0.34 to 0.11), so we do not interpret it. These results support that the Socratic agent behaved in a Socratic way. [If you keep the single-rater result on clarity and depth from the earlier coding: "In an earlier single-rater coding, the Socratic agent was also rated less clear and less deep; we did not replicate this with two raters."]

*Student behaviour.* Table 1 summarises the comparison. Without adjustment, Socratic students scored substantially higher on reasoning quality (+0.76; 0.55 to 0.96), knowledge building (+0.74; 0.53 to 0.94) and effort (+0.82; 0.62 to 1.02). Most of this difference is mechanical: the number and length of student messages alone account for about half of the variation in these scores (marginal R-squared 0.51-0.64), and the Socratic condition prompts more and longer messages. After adjusting for the number of student messages and words, the difference remained for reasoning quality (+0.29; 0.12 to 0.46; Benjamini-Hochberg-adjusted p = 0.002) and was smaller and borderline for knowledge building (+0.17; 0.01 to 0.33; adjusted p = 0.0496). Exploratory items were in the same direction: effort (+0.24; 0.10 to 0.39) and asking a content question (+0.07 on the 0-1 scale; 0.00 to 0.14, p = 0.064).

The reasoning result was stable across the pre-specified checks: it was similar when the rater saw only the student's messages (+0.30; 0.12 to 0.47), when conversations with a single student message were excluded (+0.49; 0.19 to 0.80), when the development conversations were added (+0.28; 0.11 to 0.44), and for each rater analysed alone (+0.29 in both). The knowledge-building result was less robust: it was close to zero for the Claude rater alone (+0.09; -0.08 to 0.27) and positive for the GPT rater (+0.25; 0.06 to 0.44). We therefore regard the evidence for higher reasoning as moderate, and the evidence for knowledge building as weak.

These estimates concern observable reasoning and effort in the transcript as rated by LLMs. They are not measures of learning, and they do not show that students were cognitively more engaged.
```

**Table 1** (insert after the paragraph; build it from `output/tables/tab_llm_effects.csv` for the estimates and `output/tables/tab_llm_reliability.csv` for the agreement column):

| Item | Raters' agreement | Unadjusted | Adjusted for messages and words | BH p (adjusted) | Status |
|---|---|---|---|---|---|
| Reasoning quality | alpha 0.70 | +0.76 [0.55, 0.96] | +0.29 [0.12, 0.46] | 0.002 | primary |
| Knowledge building | alpha 0.81 | +0.74 [0.53, 0.94] | +0.17 [0.01, 0.33] | 0.0496 | primary |
| Effort and task focus | alpha 0.669 | +0.82 [0.62, 1.02] | +0.24 [0.10, 0.39] | 0.002 | exploratory |
| Asked a content question (0/1) | 74% agreement, AC1 0.62 | +0.10 [0.04, 0.17] | +0.07 [0.00, 0.14] | 0.064 | exploratory |

Caption: "Socratic minus non-Socratic differences in LLM-coded student behaviour (314 holdout conversations from 85 students). Estimates are from linear mixed models with a random intercept for student and fixed effects for school and conversation order; scores are standardised averages of two LLM raters (the yes/no item is a proportion). Brackets show 95% confidence intervals. BH = Benjamini-Hochberg adjusted within the four student items."

### 2.3 Footnote at `03-results.Rmd:588` (conversation count)

**Action:** replace with: "We collected 358 conversations; four from the test account were excluded, leaving 354 conversations from 86 students, of which 314 form the holdout sample analysed here. [CONFIRM the relationship to the 122 participants and to the 366 expected chats.]"

---

## 3. Short companion edits (Introduction, Discussion, Abstract)

Reviewer 4 questions the engagement conclusions, so the wording should change wherever it appears.

- **`01-intro.Rmd` RQ3/RQ4 text** (engagement as an outcome): rename RQ4 to "How does the instructional guidance of AI agents influence what students do in the conversation?" and fold the helpfulness question into RQ3 or RQ5 (see `docs/revision_plan.md`, A1).
- **`04-discussion.Rmd:25`**, "Therefore, despite a greater engagement, we found no significant difference in student performance" -> "Therefore, although Socratic students interacted more and showed somewhat more observable reasoning in the conversation, we found no significant difference in confidence or in the correctness of their answers."
- **`04-discussion.Rmd:27`**, "...despite the greater engagement": replace "greater engagement" by "greater interaction volume".
- **`04-discussion.Rmd:39`**, "trade-off between engagement and the clarity or depth of insights": replace "engagement" by "interaction" unless the clarity/depth result is re-estimated (see item 3 in Section 0).
- **Abstract/Highlights**: wherever "engagement" is a result, rewrite as above.
- **Limitations paragraph (add)**: "The coding of conversations relies on LLM raters. Their agreement shows that the ratings are consistent but not that they are valid, we had no human coders, and several items did not reach our reliability threshold. The ratings describe what is visible in the text, and the Socratic condition mechanically produces more and longer student messages; we adjusted for this, but the adjustment cannot remove all dependence between the number of messages and the content of the ratings."

---

## 4. Appendix (`manuscript/90-supporting.Rmd`)

**Action:** replace the current section "Automatic evaluation of Socratic dimensions" (`# Automatic evaluation of Socratic dimensions {#sec:socratic-dimension}`, line ~72) with the following; keep the old rubric text only if the old figure is kept.

```markdown
# LLM-based coding of the dialogues {#sec:si-llm-protocol}

## Rubrics

The full prompts, including the score definitions, are given verbatim in the repository (`config/prompts/rate_student.txt` and `config/prompts/rate_socratic.txt`) [and reproduced below]. [PASTE the two prompts here, or add them as a supplementary file.] Table \@ref(tab:si-anchors) shows the anchors of the student items.

Table SI-A (anchors, abbreviated):

| Item | 1 | 3 | 5 |
|---|---|---|---|
| Reasoning quality | Only bare answers or repetition | A step or answer with a brief reason | Explicit, coherent argument that weighs alternatives or questions an assumption |
| Knowledge building | Ignores or only repeats earlier content | Applies earlier information to the problem | Synthesises several points, transfers them, or challenges earlier information |
| Effort and task focus | No student-authored content / off-task | At least one complete task-focused attempt, little follow-through | Persistent, detailed, self-directed work |
| Content question (0/1) | 0 = none, or only requests for the answer | | 1 = at least one question about the content |

(Scores 2 and 4 are defined in the prompt; the pasted task statement is excluded.)

## Raters, versions and settings

| Rubric | Rater | Model version returned by the API | Temperature | Date |
|---|---|---|---|---|
| Student items | GPT-4o-mini | gpt-4o-mini-2024-07-18 | 0 | 2026-11-03 |
| Student items | Claude Haiku 5.5 | claude-haiku-5-5 | provider default (the API rejected a temperature setting) | 2026-11-03 |
| AI-agent items | Claude Haiku 5.5 | claude-haiku-5-5 | provider default | 2026-11-03 |
| AI-agent items | GPT-4o | gpt-4o-2024-08-06 | 0 | 2026-11-03 |

Prompt hashes (SHA-256 prefix): student rubric `e2fac51ff3f4`, AI-agent rubric `742bf95d78b3`. All raw responses are archived in `data/llm_ratings/`. [Add repository/DOI.]

## Development phase

The rubrics were developed on 40 conversations (20 per condition, random draw, seed 20261103). On these, repeating the same rater gave stable scores (alpha 0.77-1.00 for four models), models of the same provider agreed more than models of different providers (alpha 0.63-0.68 versus about 0.45), and a first version of the effort anchors produced systematic differences between providers (GPT scored about 0.5 higher) that disappeared after we specified how to score one-word replies and the pasted task statement. The yes/no format for content questions replaced a 1-5 scale that was close to its minimum for most conversations. The Socratic rubric produced no agreement with GPT-4o-mini and was therefore rated with Claude Haiku 5.5 and GPT-4o.

## Reliability on the holdout sample

Table SI-B (314 conversations; full dialogue unless stated):

| Item | Alpha (ordinal) | Rank correlation | Agreement / AC1 | Status |
|---|---|---|---|---|
| Reasoning quality | 0.70 | 0.72 | | primary |
| Knowledge building | 0.81 | 0.81 | | primary |
| Effort and task focus | 0.669 | 0.71 | | exploratory (threshold 0.67) |
| Content question (0/1) | | | 73.6% / 0.62 | exploratory (threshold 80%) |
| Supportive guidance | 0.43 | 0.66 | | exploratory |
| Next-step guidance | 0.56 | 0.70 | | exploratory |
| Encouraging tone | -0.20 | 0.55 | | exploratory |
| Conversational flow | 0.31 | 0.59 | | exploratory |
| Identifying mistake (66 applicable) | 0.54 | 0.75 | | exploratory |
| Acknowledging mistake (66 applicable) | 0.52 | 0.71 | | exploratory |
| *Student items, student messages only:* reasoning / knowledge building / effort / content question | 0.68 / 0.65 / 0.45 / - | 0.68 / 0.65 / 0.60 / 0.16 | question: 59.6% / 0.32 | |

Alpha is negative for encouraging tone because the GPT model scored about one point higher than the Claude model on every conversation; the rank correlation (0.55) shows that the two rank conversations similarly.

## Results by rater (adjusted model, 314 conversations)

Table SI-C (`si-per-rater`): Socratic minus non-Socratic, standardised units, 95% CI.

| Item | Rater | Estimate | 95% CI |
|---|---|---|---|
| Reasoning quality | Claude Haiku 5.5 | 0.29 | 0.10, 0.48 |
| Reasoning quality | GPT-4o-mini | 0.29 | 0.10, 0.48 |
| Knowledge building | Claude Haiku 5.5 | 0.09 | -0.08, 0.27 |
| Knowledge building | GPT-4o-mini | 0.25 | 0.06, 0.44 |
| Effort | Claude Haiku 5.5 | 0.23 | 0.09, 0.38 |
| Effort | GPT-4o-mini | 0.25 | 0.07, 0.44 |
| Content question | Claude Haiku 5.5 | 0.03 | -0.05, 0.12 |
| Content question | GPT-4o-mini | 0.11 | 0.00, 0.22 |
| Supportive guidance | Claude Haiku 5.5 | 1.61 | 1.44, 1.78 |
| Supportive guidance | GPT-4o | 1.30 | 1.10, 1.51 |
| Next-step guidance | Claude Haiku 5.5 | 1.57 | 1.41, 1.74 |
| Next-step guidance | GPT-4o | 1.25 | 1.04, 1.46 |
| Encouraging tone | Claude Haiku 5.5 | 0.93 | 0.73, 1.13 |
| Encouraging tone | GPT-4o | 1.27 | 1.05, 1.49 |
| Conversational flow | Claude Haiku 5.5 | 0.34 | 0.11, 0.57 |
| Conversational flow | GPT-4o | 0.36 | 0.11, 0.60 |

## Sensitivity analyses

Table SI-D: adjusted Socratic minus non-Socratic differences.

| Item | Primary (314) | Student messages only | Excluding single-message chats (164) | All 354 chats |
|---|---|---|---|---|
| Reasoning quality | 0.29 [0.12, 0.46] | 0.30 [0.12, 0.47] | 0.49 [0.19, 0.80] | 0.28 [0.11, 0.44] |
| Knowledge building | 0.17 [0.01, 0.33] | 0.19 [0.03, 0.35] | 0.31 [0.01, 0.61] | 0.16 [0.01, 0.32] |
| Effort | 0.24 [0.10, 0.39] | 0.21 [0.04, 0.38] | 0.37 [0.13, 0.62] | 0.24 [0.10, 0.38] |
| Content question | 0.07 [0.00, 0.14] | 0.01 [-0.07, 0.09] | 0.05 [-0.07, 0.18] | 0.06 [-0.01, 0.13] |
| Supportive guidance | 1.45 [1.30, 1.61] | n/a | 1.13 [0.90, 1.37] | 1.47 [1.33, 1.61] |
| Next-step guidance | 1.41 [1.25, 1.56] | n/a | 1.09 [0.87, 1.32] | 1.43 [1.29, 1.58] |
| Encouraging tone | 1.09 [0.92, 1.27] | n/a | 1.02 [0.72, 1.33] | 1.10 [0.93, 1.27] |
| Conversational flow | 0.36 [0.14, 0.58] | n/a | 0.09 [-0.27, 0.45] | 0.36 [0.16, 0.57] |

A further pre-specified check, truncating each conversation to its first three student messages, was not carried out. [Delete this sentence if you run it, and add the column.]

## How much do message counts explain?

Table SI-E: marginal R-squared of linear mixed models with school, conversation order, log messages and log words (length only) and the same model plus condition.

| Item | Length only | Length + condition | LRT p for condition |
|---|---|---|---|
| Reasoning quality | 0.51 | 0.53 | 0.0009 |
| Knowledge building | 0.59 | 0.60 | 0.035 |
| Effort | 0.64 | 0.66 | 0.0008 |
| Content question | 0.056 | 0.067 | 0.061 |
| Supportive guidance | 0.083 | 0.58 | <0.0001 |
| Next-step guidance | 0.11 | 0.57 | <0.0001 |
| Encouraging tone | 0.11 | 0.43 | <0.0001 |
| Conversational flow | 0.22 | 0.24 | 0.0011 |

The student-behaviour scores are largely predictable from message and word counts (R-squared 0.51-0.64), whereas the AI-agent-conduct scores depend mainly on the condition. This is the reason the primary specification adjusts for interaction volume.

## Descriptives (raw scores, mean of the two raters, holdout)

| Item | Non-Socratic | Socratic |
|---|---|---|
| Reasoning quality | 1.19 | 1.79 |
| Knowledge building | 1.20 | 1.84 |
| Effort | 1.49 | 2.41 |
| Content question (0/1) | 0.15 | 0.24 |
| Supportive guidance | 1.54 | 3.22 |
| Next-step guidance | 1.67 | 3.44 |
| Encouraging tone | 2.56 | 3.31 |
| Conversational flow | 3.68 | 3.52 |

(Raw means averaged over the two raters of each item and over conversations; the student items are close to the bottom of the scale in both conditions. At least one content question was coded in 27% of non-Socratic and 38% of Socratic conversations.)

## Data and code availability

The ratings, the prompts, the pre-specification, the scripts for rating and analysis and the analysis notebook are archived at [REPO/DOI]. [Confirm that the chat logs can be shared in de-identified form before publishing them.]
```

---

## 4b. Which files from `output/` go where

All files are produced by `Rscript analysis.R` (section "RESULTS: LLM-rated student behaviour and Socratic conduct"). Tables exist as `.csv` and `.txt`; figures as `.pdf`. Paths are relative to `output/`.

| Manuscript location | File | Use |
|---|---|---|
| Results, Table 1 (main text) | `tables/tab_llm_effects.csv` | Estimates, 95% CI and BH p per item; use the 4 student rows (adjusted and unadjusted). Pair with `tables/tab_llm_reliability.csv` (agreement column, `mode == "full"`, student rubric). |
| Results, AI-agent-conduct paragraph | `tables/tab_llm_effects.csv` | Rows of family B (numbers quoted in the text). |
| Results, volume sentence ("median 3 vs 1 student messages") | `tables/tab_llm_interaction_volume.csv` | Medians of student messages and words per chat. |
| Results, Figure (optional, replaces `fig:socratic-dimensions`) | `figures/fig_llm_effects.pdf` | Forest plot, both specifications; shows both families. |
| Results, robustness sentences | `tables/tab_llm_sensitivity.csv`, `tables/tab_llm_per_rater.csv` | Numbers quoted in the reasoning and knowledge-building paragraph. |
| Appendix, "Reliability on the holdout sample" (Table SI-B) | `tables/tab_llm_reliability.csv` | All items, both modes. |
| Appendix, "Results by rater" (Table SI-C) | `tables/tab_llm_per_rater.csv` | |
| Appendix, "Sensitivity analyses" (Table SI-D) | `tables/tab_llm_sensitivity.csv` | |
| Appendix, "Sensitivity analyses" (optional figure) | `figures/fig_llm_sensitivity.pdf` | |
| Appendix, "How much do message counts explain?" (Table SI-E) | `tables/tab_llm_length_r2.csv` | |
| Appendix, "Descriptives" | `tables/tab_llm_descriptives.csv` | Means and SDs by arm. |
| Appendix (optional figure) | `figures/fig_llm_ratings_by_arm.pdf` | Distribution of scores by arm. |

Not to include: the files in `output/robustness/` and the older `tab_*`/`fig_*` files belong to the earlier analyses (accuracy, learning, perceived accuracy) and are unchanged.

Notes on integration:
- `tab_llm_*.csv` have an extra first column of row numbers; drop it. Round to two decimals (BH p to three, so that 0.0496 does not appear as 0.050).
- Read the tables in the manuscript with `read.csv(here::here("output/tables/..."))` (the manuscript's `read.csv` wrapper already resolves paths with `here`), or include the figure with `knitr::include_graphics(here::here("output/figures/fig_llm_effects.pdf"))`. The existing figures are saved in this folder too.
- Re-run `Rscript analysis.R` before building the manuscript, so the files match the data.

---

## 5. Checklist after integrating

- [ ] Re-run `Rscript analysis.R` and check that numbers in the text match `output/tables/tab_llm_*.csv` (Section 4b).
- [ ] Use "AI agent" instead of "tutor" throughout (Reviewer 4 preference), including existing text, figure titles and axis labels, e.g. "AI Tutor" in `analysis.R` (lines ~166, 174, 562, 712, 783) and in the manuscript sources. Code names (`rate_tutor`, `treatment_tutor_id`) stay as they are.
- [ ] Renumber RQ/H labels consistently (Introduction, Methods, Results, Discussion, Abstract).
- [ ] Reconcile the 354/362/366 and 86/122 counts everywhere.
- [ ] Add references (Section 0, item 7) to `refs.bib`.
- [ ] Remove or regenerate `Figure \@ref(fig:socratic-dimensions)` and the `socratic-eval` chunk that use the old single-rater scores.
- [ ] Replace "engagement" wherever it refers to message counts or to the old LLM "engagement" item.
- [ ] Commit `docs/prespecification.md`, `data/holdout_ids.json`, prompts and `data/llm_ratings/` before submission; cite the commit or DOI.
- [ ] Reply to Reviewer 4: this addresses their point 4 (engagement conclusions: message counts renamed, adjustment shown, LLM coding of student behaviour added), point 2 (analysis approaches justified in the Methods), and part of point 1 (RQ/hypothesis consistency).

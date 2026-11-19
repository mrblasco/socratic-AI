# 08_llm_ratings: LLM-rated student behaviour and Socratic conduct in the chat transcripts.
# Follows docs/prespecification.md (written before the holdout chats were rated).
# Results describe observable reasoning and effort in transcripts as rated by LLMs; they are not
# measures of learning, and rater agreement shows consistency, not validity.
#
# Inputs (produced by the separate pipeline in llm_annotation/):
#   analysis/data/processed/chats.rds
#   llm_annotation/input/holdout_ids.json
#   llm_annotation/output/llm_ratings_holdout_long.csv, llm_ratings_dev_v3_long.csv
#   llm_annotation/output/reliability_holdout/reliability_table.csv
# Writes: output/tables/tab_llm_*.csv, output/figures/fig_llm_*.pdf (names read by the manuscript)

if (!exists("save_table")) source("R/helpers.R")
suppressPackageStartupMessages({ library(lme4); library(lmerTest); library(jsonlite) })  # lmerTest: Satterthwaite p-values

LLM_DIR <- "llm_annotation"
needed <- file.path(LLM_DIR, c("input/holdout_ids.json", "output/llm_ratings_holdout_long.csv",
                               "output/llm_ratings_dev_v3_long.csv", "output/reliability_holdout/reliability_table.csv"))
if (!all(file.exists(needed))) stop("LLM annotation outputs missing: ", paste(needed[!file.exists(needed)], collapse = ", "))
ARM_FILL <- c("#d95f02", "#7570b3")

holdout <- fromJSON(file.path(LLM_DIR, "input", "holdout_ids.json"))

# ---- Chat-level covariates (one row per chat) -----------------------------------------
# No task identifier exists in the chat data: chat order within student is the pre-specified proxy.
chats <- readRDS("analysis/data/processed/chats.rds")
chat_info <- chats %>%
  filter(user_id != 1) %>%                                   # drop the test user
  group_by(chat_id) %>%
  summarise(student = first(user_id), arm = first(treatment_tutor_id), school = first(location),
            start = min(created_at), n_msgs = sum(role == "user"), n_words = sum(words[role == "user"], na.rm = TRUE),
            .groups = "drop") %>%
  group_by(student) %>% mutate(chat_order = rank(start, ties.method = "first")) %>% ungroup() %>%
  mutate(arm = factor(arm, c("non_socratic", "socratic")), log_msgs = log(n_msgs), log_words = log1p(n_words))

ratings <- read_csv(file.path(LLM_DIR, "output", "llm_ratings_holdout_long.csv"), show_col_types = FALSE) %>%
  mutate(rubric = sub("^rate_", "", sub("__.*", "", rater)), mode = ifelse(student_only, "student_only", "full"))
stopifnot(setequal(unique(ratings$chat_id), holdout))

# ---- Reliability gate (pre-specified: ordinal alpha >= .67; binary >= 80% agreement and AC1 >= .60) ----
rel <- read_csv(file.path(LLM_DIR, "output", "reliability_holdout", "reliability_table.csv"), show_col_types = FALSE) %>%
  transmute(rubric = sub("^rate_", "", prompt), mode = ifelse(mode == "student", "student_only", mode),
            item = dimension, n = n_chats, alpha = alpha_between_models, spearman, pct_agree, ac1) %>%
  mutate(pass = ifelse(!is.na(pct_agree), pct_agree >= 80 & ac1 >= 0.60, alpha >= 0.67),
         status = ifelse(pass, "primary", "exploratory"))
save_table(rel, "tab_llm_reliability")
item_status <- rel %>% filter(mode == "full") %>% select(rubric, item, status)

# ---- Outcomes: mean of the two raters' z-scores (question_asking: mean of the 0/1 ratings) ----
items <- tibble(
  rubric = c(rep("student", 4), rep("socratic", 4)),
  item   = c("reasoning_quality", "knowledge_building", "effort_seriousness", "question_asking",
             "supportive_guidance", "next_step_guidance", "encouraging_tone", "conversational_flow"),
  family = c(rep("A: student behaviour", 4), rep("B: Socratic conduct", 4))
)
ratings_z <- ratings %>%
  rename(item = dimension) %>% semi_join(items, by = c("rubric", "item")) %>%
  group_by(rubric, mode, item, model) %>%
  mutate(z = ifelse(item == "question_asking", score, as.numeric(scale(score)))) %>% ungroup()

outcome <- ratings_z %>%
  group_by(chat_id, rubric, mode, item) %>% summarise(y = mean(z, na.rm = TRUE), .groups = "drop") %>%
  left_join(chat_info, by = "chat_id")

# ---- Descriptives -----------------------------------------------------------------------
save_table(outcome %>% filter(mode == "full") %>% group_by(rubric, item, arm) %>%
             summarise(mean = mean(y), sd = sd(y), n = n(), .groups = "drop"), "tab_llm_descriptives")
save_table(chat_info %>% filter(chat_id %in% holdout) %>% group_by(arm) %>%
             summarise(chats = n(), students = n_distinct(student), median_student_msgs = median(n_msgs),
                       median_student_words = median(n_words), .groups = "drop"), "tab_llm_interaction_volume")

fig <- ggplot(filter(outcome, mode == "full"), aes(arm, y, fill = arm)) +
  geom_violin(alpha = .4, colour = NA) + stat_summary(fun = mean, geom = "point", size = 2.5) +
  facet_wrap(~item, scales = "free_y", nrow = 2) + scale_fill_manual(values = ARM_FILL) + guides(fill = "none") +
  labs(x = NULL, y = "Item score (mean of two raters' z-scores)", title = "LLM ratings by arm (holdout, full dialogue)")
save_figure(fig, "fig_llm_ratings_by_arm", width = 9, height = 5.5)

# ---- Primary models -----------------------------------------------------------------------
# score ~ arm + school + chat order [+ log messages + log words] + (1 | student); the adjusted
# model (for interaction volume) is the pre-specified headline.
llm_fit <- function(d, adjusted) {
  f <- if (adjusted) y ~ arm + school + chat_order + log_msgs + log_words + (1 | student)
       else y ~ arm + school + chat_order + (1 | student)
  m  <- lmer(f, d, REML = TRUE, control = lmerControl(optimizer = "bobyqa"))
  cf <- summary(m)$coefficients["armsocratic", ]
  ci <- suppressMessages(confint(m, "armsocratic", method = "Wald"))
  tibble(est = cf[["Estimate"]], se = cf[["Std. Error"]], p = cf[["Pr(>|t|)"]], lo = ci[1], hi = ci[2],
         n = nobs(m), students = lme4::ngrps(m)[["student"]])
}
llm_run <- function(data, mode_sel = "full", label = "primary", specs = c("unadjusted", "adjusted")) {
  data %>% filter(mode == mode_sel) %>% group_by(rubric, item) %>%
    group_modify(~ bind_rows(lapply(specs, function(s) mutate(llm_fit(.x, s == "adjusted"), spec = s)))) %>%
    ungroup() %>% mutate(analysis = label)
}

res <- llm_run(filter(outcome, chat_id %in% holdout)) %>%
  left_join(items, by = c("rubric", "item")) %>%
  group_by(family, spec) %>% mutate(p_bh = p.adjust(p, "BH")) %>% ungroup() %>%   # Benjamini-Hochberg within family
  left_join(item_status, by = c("rubric", "item")) %>%
  arrange(family, item, spec)
save_table(select(res, family, item, status, spec, est, lo, hi, p, p_bh, n, students), "tab_llm_effects")

fig <- ggplot(res, aes(est, reorder(item, est), colour = spec, shape = status)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(.5)) +
  facet_grid(family ~ ., scales = "free_y", space = "free_y") +
  scale_colour_manual(values = c("navy", "orange")) +
  labs(x = "Socratic − non-Socratic (z units; 95% CI)", y = NULL, colour = NULL, shape = "Reliability",
       title = "Unadjusted vs adjusted for message and word counts")
save_figure(fig, "fig_llm_effects", width = 8, height = 6)

# ---- Sensitivity 2: each rater separately -------------------------------------------------------
per_rater <- ratings_z %>% filter(mode == "full", chat_id %in% holdout) %>%
  mutate(y = z) %>% left_join(chat_info, by = "chat_id") %>%
  group_by(rubric, item, model) %>% group_modify(~ llm_fit(.x, TRUE)) %>% ungroup()
save_table(per_rater, "tab_llm_per_rater")

# ---- Sensitivity 1, 4, 5 --------------------------------------------------------------------------
adj <- function(d, label) llm_run(d, "full", label, "adjusted")
s4 <- adj(filter(outcome, chat_id %in% holdout, n_msgs > 1), "excl. 1-message chats")
s1 <- llm_run(filter(outcome, chat_id %in% holdout, rubric == "student"), "student_only", "student-only ratings", "adjusted")

# 5: all 354 chats = holdout + development chats rated with the same frozen prompts and raters
dev <- read_csv(file.path(LLM_DIR, "output", "llm_ratings_dev_v3_long.csv"), show_col_types = FALSE) %>%
  filter(rep == 1, !student_only) %>%
  mutate(rubric = sub("^rate_", "", sub("__.*", "", rater)), mode = "full") %>% rename(item = dimension)
rater_pairs <- tibble(rubric = c("student", "student", "socratic", "socratic"),
                      model  = c("gpt-4o-mini", "claude-haiku-5-5", "claude-haiku-5-5", "gpt-4o"))
same_prompt <- ratings %>% distinct(rubric, prompt_hash) %>% inner_join(distinct(dev, rubric, prompt_hash), by = c("rubric", "prompt_hash"))
dev <- dev %>% semi_join(rater_pairs, by = c("rubric", "model")) %>%
  semi_join(same_prompt, by = c("rubric", "prompt_hash")) %>% semi_join(items, by = c("rubric", "item"))
outcome_all <- bind_rows(select(filter(ratings_z, mode == "full"), chat_id, rubric, mode, item, model, score),
                         select(dev, chat_id, rubric, mode, item, model, score)) %>%
  group_by(rubric, item, model) %>% mutate(z = ifelse(item == "question_asking", score, as.numeric(scale(score)))) %>% ungroup() %>%
  group_by(chat_id, rubric, mode, item) %>% summarise(y = mean(z, na.rm = TRUE), .groups = "drop") %>%
  left_join(chat_info, by = "chat_id")
s5 <- adj(outcome_all, "all chats (holdout + development)")

sens <- bind_rows(mutate(filter(res, spec == "adjusted"), analysis = "primary (holdout)"), s4, s1, s5) %>%
  select(analysis, rubric, item, est, lo, hi, p, n)
save_table(sens, "tab_llm_sensitivity")
fig <- ggplot(sens, aes(est, analysis)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey50") + geom_pointrange(aes(xmin = lo, xmax = hi)) +
  facet_wrap(~item, scales = "free_x", nrow = 2) + labs(x = "Socratic − non-Socratic (95% CI)", y = NULL)
save_figure(fig, "fig_llm_sensitivity", width = 11, height = 6)

# ---- Sensitivity 6: does the rating carry information beyond interaction volume? ---------------------
r2_marginal <- function(m) {
  vf <- var(as.vector(model.matrix(m) %*% fixef(m)))
  vf / (vf + sum(sapply(VarCorr(m), function(x) as.numeric(x))) + sigma(m)^2)
}
len <- outcome %>% filter(mode == "full", chat_id %in% holdout) %>% group_by(rubric, item) %>%
  group_modify(~ {
    m0 <- lmer(y ~ school + chat_order + log_msgs + log_words + (1 | student), .x, REML = FALSE)
    m1 <- update(m0, . ~ . + arm)
    tibble(R2_length_only = r2_marginal(m0), R2_length_plus_arm = r2_marginal(m1),
           LRT_p_arm_given_length = anova(m0, m1)[["Pr(>Chisq)"]][2])
  }) %>% ungroup()
save_table(len, "tab_llm_length_r2")

# Sensitivity 3 (truncate each chat to its first 3 student messages) needs re-rating by the LLMs; not run here.

# ---- Interaction volume (H5a): student messages and words per conversation, all conversations ----
# Descriptive medians, Wilcoxon rank-sum (ignores that students contribute several chats) and a mixed model on
# the log scale with a random intercept for student; exp(est) is the ratio Socratic / non-Socratic.
vol <- chat_info %>% mutate(school = factor(school))
vol_tests <- bind_rows(lapply(list(c("n_msgs", "log_msgs", "Student messages"), c("n_words", "log_words", "Student words")), function(m) {
  raw_v <- vol[[m[1]]]
  fit <- lmer(reformulate(c("arm", "school", "chat_order", "(1 | student)"), m[2]), vol, REML = TRUE,
              control = lmerControl(optimizer = "bobyqa"))
  cf <- summary(fit)$coefficients["armsocratic", ]
  ci <- suppressMessages(confint(fit, "armsocratic", method = "Wald"))
  tibble(measure = m[3],
         median_non_socratic = median(raw_v[vol$arm == "non_socratic"]), median_socratic = median(raw_v[vol$arm == "socratic"]),
         wilcoxon_p = wilcox.test(raw_v ~ vol$arm, exact = FALSE)$p.value,
         ratio = exp(cf[["Estimate"]]), ratio_lo = exp(ci[1]), ratio_hi = exp(ci[2]), p_mixed = cf[["Pr(>|t|)"]],
         chats = nobs(fit), students = lme4::ngrps(fit)[["student"]])
}))
save_table(vol_tests, "tab_llm_volume_tests")

# 03_correctness: Task 3 correctness (primary K3), calibration, learning transitions, retention.
# Reads:  dd, raw
# Writes: output/tables/correctness_*.csv, calibration_*.csv, learning_transitions.csv,
#         retention_*.csv; output/figures/correctness.pdf, calibration.pdf

if (!exists("dd")) { source("R/helpers.R"); source("steps/00_data.R") }
suppressPackageStartupMessages(library(marginaleffects))

dk3 <- task_data(dd, 3)
covs3 <- covs_for(3)

# ---- Descriptives -------------------------------------------------------------
save_table(dd %>% group_by(arm) %>% summarise(n = n(), pct_correct_before = 100 * mean(pre_correct), pct_correct_after = 100 * mean(post_correct)),
           "correctness_descriptives")

pc <- dd %>% pivot_longer(c(pre_correct, post_correct), names_to = "time", values_to = "y") %>%
  mutate(time = factor(time, c("pre_correct", "post_correct"), c("Before AI", "After AI"))) %>%
  group_by(arm, time) %>% reframe(prop_ci(y))
fig <- ggplot(pc, aes(time, p, fill = arm)) +
  geom_col(position = position_dodge(.8), width = .75) +
  geom_errorbar(aes(ymin = lo, ymax = hi), position = position_dodge(.8), width = .2) +
  scale_fill_manual(values = COL) + scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(x = NULL, y = "Correct answers", fill = NULL, title = "Task 3 correctness, with 95% Wilson CIs")
save_figure(fig, "correctness")

# ---- K3: effect on correctness after AI (linear probability model; logit AME as a check) ----
m_u <- lm(post_correct ~ z, dk3)
m_a <- lm(fml("post_correct", covs3), dk3)
m_l <- glm(fml("post_correct", covs3), binomial, dk3)
ame <- avg_comparisons(m_l, variables = "z", vcov = "HC2")
k3 <- bind_rows(
  tibble(model = "Unadjusted risk difference (LPM, HC2)", tr(ci_hc2(m_u))),
  tibble(model = "Adjusted risk difference (LPM, HC2)",   tr(ci_hc2(m_a))),
  tibble(model = "Adjusted AME (logit, HC2)", est = ame$estimate, lo = ame$conf.low, hi = ame$conf.high, p = ame$p.value)
) %>% mutate(outcome = "K3", .before = 1)
save_table(k3, "correctness_effects")

or_k <- exp(cbind(OR = coef(m_l), confint.default(m_l, vcov. = vcovHC(m_l, "HC2"))))["z", ]
h <- 2 * asin(sqrt(mean(dk3$post_correct[dk3$z == 1]))) - 2 * asin(sqrt(mean(dk3$post_correct[dk3$z == 0])))
save_table(tibble(or = or_k[[1]], lo = or_k[[2]], hi = or_k[[3]], cohens_h = h), "correctness_odds_ratio")

# ---- Learning transitions (before -> after) -----------------------------------
save_table(dk3 %>% count(arm, pre_correct, post_correct) %>% group_by(arm, pre_correct) %>% mutate(pct_of_row = 100 * n / sum(n)),
           "learning_transitions")

# ---- Calibration: does confidence track correctness, and does the tutor change that? ----
save_table(dk3 %>% group_by(arm, post_correct) %>% summarise(n = n(), mean_confidence = mean(conf), .groups = "drop"), "calibration_means")
ct <- hc2(lm(conf ~ z * post_correct + sev + eff + pre_correct, dk3))
save_table(tibble(term = rownames(ct), estimate = ct[, 1], se = ct[, 2], p = ct[, 4]) %>% filter(term %in% c("z", "post_correct", "z:post_correct")),
           "calibration_interaction")

fig <- ggplot(dk3 %>% mutate(answer = factor(post_correct, 0:1, c("Incorrect", "Correct"))), aes(answer, conf, colour = arm)) +
  geom_point(position = position_jitterdodge(jitter.width = .15, jitter.height = .1, dodge.width = .6), alpha = .5) +
  stat_summary(fun.data = ggplot2::mean_cl_normal, geom = "pointrange", position = position_dodge(.6), linewidth = 1, colour = "black", aes(group = arm)) +
  scale_colour_manual(values = COL) +
  labs(x = "Answer after AI (Task 3)", y = "Confidence (1-5)", colour = NULL, title = "Confidence by correctness (black = mean, 95% CI)")
save_figure(fig, "calibration")

# ---- Retention: the transfer question answered without AI ------------------------
# Stored answers use different codes in each school (Seville numeric, Brussels Likert-style labels).
# Coding taken as correct: "3" (Seville) and "neutral" (Brussels) = Gold; all other codes = incorrect.
save_table(as.data.frame(table(code = raw$q29_sound_speed_verify, school = raw$location)), "retention_raw_codes_by_school")

code_gold <- function(v) case_match(v, c("3", "neutral") ~ 1L, c("0", "1", "2", "4", "very_helpful", "helpful", "not_very_helpful") ~ 0L)
vv <- dk3 %>% mutate(verify_correct = code_gold(verify_raw))
dv <- vv %>% filter(!is.na(verify_correct))
covs <- c(if (n_distinct(dv$sev) > 1) "sev", "eff", "pre_correct")
ret <- bind_rows(
  tibble(model = "Unadjusted", n = nrow(dv), pct_correct = 100 * mean(dv$verify_correct), tr(ci_hc2(lm(fml("verify_correct", NULL), dv)))),
  tibble(model = "Adjusted", n = nrow(dv), pct_correct = 100 * mean(dv$verify_correct), tr(ci_hc2(lm(fml("verify_correct", covs), dv))))
)
save_table(ret, "retention_effects")

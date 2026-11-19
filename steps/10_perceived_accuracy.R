# 10_perceived_accuracy: Experiment 1 (RQ2), perceived accuracy of the AI estimate and of the
# human average guess, with vs without the AI's step-by-step explanation.
# Both estimates were identical for all students (AI: US$ 213; human average of 600 people: US$ 596).
# Ratings are on a 5-point scale (1 = very poor ... 5 = very good).
# Reads:  raw, d
# Writes: output/tables/perceived_accuracy_descriptives.csv, perceived_accuracy_effects.csv

if (!exists("d")) { source("R/helpers.R"); source("steps/00_data.R") }

ACC_LEVELS <- c("very_poor", "poor", "neutral", "good", "very_good")

pa <- raw %>%
  filter(student_id > 1) %>%
  transmute(
    id = student_id,
    ai = as.integer(factor(as.character(q10_guess_coins_ai_accuracy), ACC_LEVELS)),
    human = as.integer(factor(as.character(q11_guess_coins_human_accuracy), ACC_LEVELS))
  ) %>%
  inner_join(d %>% select(id, explain, school, sev, gender, used_ai_before), by = "id") %>%
  mutate(z = as.integer(explain == "Yes"))     # 1 = saw the explanation (helpers expect `z`)

long <- pa %>% pivot_longer(c(ai, human), names_to = "target", values_to = "y") %>% filter(!is.na(y)) %>%
  mutate(target = factor(target, c("ai", "human"), c("AI estimate", "Human average")))

desc <- long %>% group_by(target, explain) %>%
  summarise(n = n(), mean = mean(y), pct_good = 100 * mean(y >= 4), pct_neutral = 100 * mean(y == 3),
            pct_poor = 100 * mean(y <= 2), .groups = "drop") %>%
  left_join(long %>% group_by(target) %>%
              summarise(wilcoxon_p = wilcox.test(y ~ z, exact = FALSE)$p.value, .groups = "drop"), by = "target")
save_table(desc, "perceived_accuracy_descriptives")

# Effects of the explanation: ordinal logit (odds ratio, >1 = higher perceived accuracy) and OLS (points)
covs <- c("sev", "gender", "used_ai_before")
eff <- bind_rows(lapply(levels(long$target), function(tg) {
  dk <- long %>% filter(target == tg) %>% mutate(y_f = factor(y, 1:5, ordered = TRUE))
  da <- dk %>% filter(!is.na(gender))
  bind_rows(
    tibble(model = "Ordinal logit, unadjusted (OR)", n = nrow(dk), tr(or_ci(polr(y_f ~ z, droplevels(dk), Hess = TRUE)))),
    tibble(model = "Ordinal logit, adjusted (OR)",   n = nrow(da), tr(or_ci(polr(fml("y_f", covs), droplevels(da), Hess = TRUE)))),
    tibble(model = "OLS, unadjusted (points)",       n = nrow(dk), tr(ci_hc2(lm(y ~ z, dk)))),
    tibble(model = "OLS, adjusted (points)",         n = nrow(da), tr(ci_hc2(lm(fml("y", covs), da))))
  ) %>% mutate(target = tg, .before = 1)
}))
save_table(eff, "perceived_accuracy_effects")

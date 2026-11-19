# 02_confidence: effect of the Socratic tutor on self-confidence, Tasks 1-3 (primary C1-C3).
# Reads:  dd
# Writes: output/tables/confidence_descriptives.csv, confidence_effects.csv, confidence_effect_sizes.csv,
#         confidence_prop_odds_check.csv, confidence_pooled.csv; output/figures/confidence_distribution.pdf

if (!exists("dd")) { source("R/helpers.R"); source("steps/00_data.R") }

# ---- Descriptives -------------------------------------------------------------
desc <- bind_rows(lapply(1:3, function(k) {
  task_data(dd, k) %>% group_by(arm) %>%
    summarise(task = TASKS[[k]], n = n(), mean = mean(conf), sd = sd(conf), pct_confident = 100 * mean(conf >= 4), .groups = "drop")
})) %>% select(task, arm, everything())
save_table(desc, "confidence_descriptives")

dist <- bind_rows(lapply(1:3, function(k) task_data(dd, k) %>% mutate(task = TASKS[[k]]))) %>%
  count(task, arm, conf_f) %>% group_by(task, arm) %>% mutate(share = n / sum(n))
fig <- ggplot(dist, aes(share, arm, fill = conf_f)) +
  geom_col(width = .6) + facet_wrap(~ task, ncol = 1) +
  scale_fill_brewer(palette = "RdYlBu", labels = c("Not at all", "Not very", "Neutral", "Confident", "Very confident"), name = "Confidence") +
  scale_x_continuous(labels = scales::percent) +
  labs(x = NULL, y = NULL, title = "Self-confidence in the answer, by task and arm") +
  theme(strip.text = element_text(hjust = 0))
save_figure(fig, "confidence_distribution", height = 6)

# ---- Effects: ordinal logit (primary, odds ratios) and OLS (scale points) --------
effects <- list(); sizes <- list()
for (i in 1:3) {
  o <- PRIMARY[i, ]; dk <- task_data(dd, o$task); covs <- covs_for(o$task)
  ol_u <- polr(conf_f ~ z, droplevels(dk), Hess = TRUE)
  ol_a <- polr(fml("conf_f", covs), droplevels(dk), Hess = TRUE)
  ls_u <- lm(conf ~ z, dk); ls_a <- lm(fml("conf", covs), dk)
  effects[[i]] <- bind_rows(
    tibble(model = "Ordinal logit, unadjusted (OR)", tr(or_ci(ol_u))),
    tibble(model = "Ordinal logit, adjusted (OR)",   tr(or_ci(ol_a))),
    tibble(model = "OLS, unadjusted (points)",       tr(ci_hc2(ls_u))),
    tibble(model = "OLS, adjusted (points)",         tr(ci_hc2(ls_a)))
  ) %>% mutate(outcome = o$id, label = o$label, .before = 1)

  wt <- wilcox.test(conf ~ z, dk, exact = FALSE)
  r <- rank(dk$conf); n1 <- sum(dk$z); n0 <- sum(1 - dk$z)
  sizes[[i]] <- tibble(outcome = o$id, label = o$label, n = nrow(dk), sd = sd(dk$conf),
                       adj_effect_sd = unname(coef(ls_a)["z"]) / sd(dk$conf), wilcoxon_p = wt$p.value,
                       prob_superiority = (sum(r[dk$z == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0))
}
save_table(bind_rows(effects), "confidence_effects")
save_table(bind_rows(sizes), "confidence_effect_sizes")

# Proportional-odds check: log-odds of exceeding each cut-point should be similar.
# (">= 2" is omitted: too few students in the lowest category.)
po <- bind_rows(lapply(1:3, function(i) {
  dk <- task_data(dd, PRIMARY$task[i])
  bind_rows(lapply(3:5, function(k) {
    m <- glm(I(conf >= k) ~ z, binomial, dk)
    tibble(outcome = PRIMARY$id[i], cutoff = paste0(">= ", k), logOR = unname(coef(m)["z"]), se = unname(sqrt(vcov(m)["z", "z"])))
  }))
}))
save_table(po, "confidence_prop_odds_check")

# ---- Pooled effect across the three tasks (confidence standardised within task) -----
long <- bind_rows(lapply(1:3, function(k) {
  dd %>% transmute(id, z, sev, task = factor(k), y = .data[[paste0("conf", k)]], eff = .data[[paste0("eff", k)]])
})) %>%
  group_by(task) %>% mutate(y = (y - mean(y)) / sd(y), zeff = (eff - mean(eff)) / sd(eff)) %>% ungroup()
save_table(pooled_effect(long), "confidence_pooled")

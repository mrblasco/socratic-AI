# 06_exploratory_summary: heterogeneity by school, Task 2 opinion change, tutor usage, summary forest plot.
# Reads:  dd, and output/tables/confidence_effects.csv, confidence_effect_sizes.csv, confidence_pooled.csv,
#         correctness_effects.csv (steps 02, 03)
# Writes: output/tables/exploratory_*.csv; output/figures/summary_forest.pdf

if (!exists("dd")) { source("R/helpers.R"); source("steps/00_data.R") }

# ---- Heterogeneity: treatment x school interaction for each primary outcome ------
het <- bind_rows(lapply(1:4, function(i) {
  o <- PRIMARY[i, ]; dk <- task_data(dd, o$task)
  ct <- hc2(lm(reformulate(c("z", covs_for(o$task), "z:sev"), o$y), dk))
  tibble(outcome = o$id, label = o$label, interaction_seville = ct["z:sev", 1], se = ct["z:sev", 2], p = ct["z:sev", 4])
}))
save_table(het, "exploratory_heterogeneity_school")

# ---- Task 2: did the tutor change students' opinions? (no correct answer; not accuracy) ----
o2 <- dd %>% filter(!is.na(op_pre), !is.na(op_post)) %>%
  mutate(changed = as.integer(op_post != op_pre), shift = op_post - op_pre, abs_shift = abs(shift))
save_table(o2 %>% group_by(arm) %>% summarise(n = n(), pct_changed = 100 * mean(changed), mean_shift = mean(shift), mean_abs_shift = mean(abs_shift)),
           "exploratory_opinion_descriptives")
save_table(bind_rows(
  tibble(outcome = "Changed opinion (prob.)", tr(ci_hc2(lm(changed ~ z + sev + eff2, o2)))),
  tibble(outcome = "Absolute shift (points)", tr(ci_hc2(lm(abs_shift ~ z + sev + eff2, o2)))),
  tibble(outcome = "Signed shift (points)",   tr(ci_hc2(lm(shift ~ z + sev + eff2, o2))))
), "exploratory_opinion_effects")

# ---- Tutor usage: post-treatment, so described only (never used as a covariate) ----
usage <- bind_rows(lapply(1:3, function(k) {
  dk <- dd %>% mutate(turns = .data[[paste0("turns", k)]])
  p <- wilcox.test(turns ~ z, dk, exact = FALSE)$p.value
  dk %>% group_by(arm) %>%
    summarise(task = TASKS[[k]], observed = sum(!is.na(turns)), median = median(turns, na.rm = TRUE), mean = mean(turns, na.rm = TRUE), .groups = "drop") %>%
    mutate(wilcoxon_p = p)
})) %>% select(task, arm, everything())
save_table(usage, "exploratory_tutor_usage")

# ---- Summary forest plot (adjusted effects) ---------------------------------------
sizes <- read_table("confidence_effect_sizes")
conf <- read_table("confidence_effects") %>% filter(model == "OLS, adjusted (points)") %>%
  left_join(sizes %>% select(outcome, sd), by = "outcome") %>%
  transmute(panel = "Confidence (adjusted effect, SD of 1-5 scale)", outcome = label, est = est / sd, lo = lo / sd, hi = hi / sd)
pooled <- read_table("confidence_pooled") %>%
  transmute(panel = "Confidence (adjusted effect, SD of 1-5 scale)", outcome = "Pooled, 3 tasks", est, lo, hi)
corr <- read_table("correctness_effects") %>% filter(model == "Adjusted risk difference (LPM, HC2)") %>%
  transmute(panel = "Correctness (adjusted effect, percentage points)", outcome = PRIMARY$label[4], est = 100 * est, lo = 100 * lo, hi = 100 * hi)
fp <- bind_rows(conf, pooled, corr) %>% mutate(outcome = factor(outcome, rev(unique(outcome))))

fig <- ggplot(fp, aes(est, outcome)) +
  geom_vline(xintercept = 0, colour = "grey50") +
  geom_pointrange(aes(xmin = lo, xmax = hi), colour = COL["Socratic"], linewidth = .8) +
  facet_wrap(~ panel, scales = "free", ncol = 1) +
  labs(x = "Effect of Socratic vs non-Socratic tutor (95% CI)", y = NULL) +
  theme(strip.text = element_text(hjust = 0))
save_figure(fig, "summary_forest", height = 4.2)

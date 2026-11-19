# 06_exploratory_summary: heterogeneity by school and by prior ChatGPT use, Task 2 opinion change, tutor usage, summary forest plot.
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

# ---- Heterogeneity: treatment x student characteristic (prior ChatGPT use, gender) -------
# Primary outcomes and helpfulness in each task, same adjustment set as the main models, HC2 errors.
# "mod" = 1 for students who had used ChatGPT before / for girls; the interaction is Socratic x mod.
dd_m <- dd %>% mutate(prior_ai = as.integer(used_ai_before == "Yes"), girl = as.integer(gender == "Girl"))
int_row <- function(y, covs, data, mod, label, outcome) {
  data$mod <- data[[mod]]; data <- data %>% filter(!is.na(mod))
  ct <- hc2(lm(reformulate(c("z", "mod", "z:mod", covs), y), data))
  tibble(moderator = mod, outcome = outcome, label = label, n = nrow(data),
         effect_mod0 = ct["z", 1], effect_mod1_extra = ct["z:mod", 1], se_interaction = ct["z:mod", 2], p_interaction = ct["z:mod", 4])
}
het_mod <- bind_rows(lapply(c("prior_ai", "girl"), function(m) bind_rows(
  lapply(1:4, function(i) { o <- PRIMARY[i, ]; int_row(o$y, covs_for(o$task), task_data(dd_m, o$task), m, o$label, o$id) }),
  lapply(1:3, function(k) { hd <- task_data(dd_m, k) %>% mutate(help = help_code(.data[[paste0("h", k, "_raw")]], school)) %>% filter(!is.na(help))
                            int_row("help", covs_for(k), hd, m, paste("Helpfulness, Task", k), paste0("H", k)) }))))
save_table(het_mod, "exploratory_heterogeneity_student")
save_table(bind_rows(dd_m %>% count(arm, level = used_ai_before) %>% mutate(characteristic = "prior_ai"),
                     dd_m %>% count(arm, level = gender) %>% mutate(characteristic = "gender")), "exploratory_student_chars_by_arm")

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

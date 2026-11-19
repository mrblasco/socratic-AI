# 04_helpfulness: perceived helpfulness of the AI tutor, Tasks 1-3 (secondary outcome).
# CAVEAT: the two schools used different 5-point answer scales; help_code() (R/helpers.R) aligns
# them by position. Within-school and alternative-recode checks are saved too.
# Reads:  dd
# Writes: output/tables/helpfulness_*.csv; output/figures/helpfulness_distribution.pdf

if (!exists("dd")) { source("R/helpers.R"); source("steps/00_data.R") }

# Helpfulness data for task k; `very` sets the value of Seville's "Very helpful"
help_data <- function(k, very = 4L) {
  task_data(dd, k) %>%
    mutate(help = help_code(.data[[paste0("h", k, "_raw")]], school, very), help_f = factor(help, 1:5, ordered = TRUE)) %>%
    filter(!is.na(help))
}

# ---- Descriptives -------------------------------------------------------------
desc <- bind_rows(lapply(1:3, function(k) {
  help_data(k) %>% group_by(arm) %>%
    summarise(task = TASKS[[k]], n = n(), mean = mean(help), sd = sd(help), pct_rated_4_5 = 100 * mean(help >= 4), .groups = "drop")
})) %>% select(task, arm, everything())
save_table(desc, "helpfulness_descriptives")

dist <- bind_rows(lapply(1:3, function(k) help_data(k) %>% mutate(task = TASKS[[k]]))) %>%
  count(task, arm, help_f) %>% group_by(task, arm) %>% mutate(share = n / sum(n))
fig <- ggplot(dist, aes(share, arm, fill = help_f)) +
  geom_col(width = .6) + facet_wrap(~ task, ncol = 1) +
  scale_fill_brewer(palette = "RdYlBu", name = "Helpfulness\n(1 = lowest)") + scale_x_continuous(labels = scales::percent) +
  labs(x = NULL, y = NULL, title = "Perceived helpfulness of the AI tutor, by task and arm") +
  theme(strip.text = element_text(hjust = 0))
save_figure(fig, "helpfulness_distribution", height = 6)

# ---- Adjusted effects ---------------------------------------------------------
effects <- bind_rows(lapply(1:3, function(k) {
  covs <- covs_for(k); hd <- help_data(k)
  bind_rows(
    tibble(model = "Ordinal logit, adjusted (OR)", tr(or_ci(polr(fml("help_f", covs), droplevels(hd), Hess = TRUE)))),
    tibble(model = "OLS, adjusted (points)",       tr(ci_hc2(lm(fml("help", covs), hd)))),
    tibble(model = "Rated 4-5, adjusted (prob.)",  tr(ci_hc2(lm(fml("I(help >= 4)", covs), hd))))
  ) %>% mutate(task = TASKS[[k]], .before = 1)
}))
save_table(effects, "helpfulness_effects")

# ---- Checks that do not depend on how the schools' scales are aligned ----------
checks <- bind_rows(lapply(1:3, function(k) {
  covs <- setdiff(covs_for(k), "sev")
  within <- bind_rows(lapply(c(Brussels = 0, Seville = 1), function(sv) {
    hd <- help_data(k) %>% filter(sev == sv)
    tibble(task = TASKS[[k]], check = paste0("Within school: ", if (sv == 0) "Brussels" else "Seville", " (ordinal OR)"),
           n = nrow(hd), tr(or_ci(polr(fml("help_f", covs), droplevels(hd), Hess = TRUE))))
  }))
  hd5 <- help_data(k, very = 5L)
  alt <- tibble(task = TASKS[[k]], check = "Manuscript recode, pooled (ordinal OR)", n = nrow(hd5),
                tr(or_ci(polr(fml("help_f", c("sev", covs)), droplevels(hd5), Hess = TRUE))))
  bind_rows(within, alt)
}))
save_table(checks, "helpfulness_checks")

# ---- Pooled over tasks (helpfulness standardised within task) -------------------
long <- bind_rows(lapply(1:3, function(k) help_data(k) %>% transmute(id, z, sev, task = factor(k), y = help, eff))) %>%
  group_by(task) %>% mutate(y = (y - mean(y)) / sd(y), zeff = (eff - mean(eff)) / sd(eff)) %>% ungroup()
save_table(pooled_effect(long), "helpfulness_pooled")

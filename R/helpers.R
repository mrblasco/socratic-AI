# =============================================================================
# R/helpers.R: small shared functions for the analysis steps in steps/
#
# Sections: packages and constants | outcomes | statistics | saving results
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(tibble); library(readr); library(ggplot2)
  library(sandwich); library(lmtest); library(MASS)
})
select <- dplyr::select   # MASS masks dplyr::select
theme_set(theme_minimal(base_size = 12))

# ---- Constants ----------------------------------------------------------------
COL   <- c("Non-Socratic" = "#7a7a7a", "Socratic" = "#c2410c")
TASKS <- c("1" = "Task 1: water estimate", "2" = "Task 2: social-media essay", "3" = "Task 3: sound physics")
CONF_LEVELS <- c("not_confident_at_all", "not_very_confident", "neutral", "confident", "very_confident")
OPIN_LEVELS <- c("very_negative", "negative", "neutral", "positive", "very_positive")
N_PERMUTATIONS <- 5000

# ---- Outcomes -----------------------------------------------------------------
# The four primary outcomes (the Holm family). To add one, add a row here.
PRIMARY <- tribble(
  ~id,  ~label,                  ~y,             ~task,
  "C1", "C1  Confidence, Task 1", "conf",         1,
  "C2", "C2  Confidence, Task 2", "conf",         2,
  "C3", "C3  Confidence, Task 3", "conf",         3,
  "K3", "K3  Correct, Task 3",    "post_correct", 3
)

# Pre-specified adjustment set: school, task-specific self-efficacy, and for
# Task 3 the baseline (pre-AI) correctness.
covs_for <- function(task) c("sev", "eff", if (task == 3) "pre_correct")

# Analysis data for task k: adds conf, conf_f, eff (task-specific) to `dd`.
task_data <- function(dd, k) {
  dd %>% mutate(conf = .data[[paste0("conf", k)]], eff = .data[[paste0("eff", k)]],
                conf_f = factor(conf, 1:5, ordered = TRUE))
}

# Helpfulness: the two schools used different 5-point scales; map both to 1-5
# by position (Seville "Very" = 4 by default; the manuscript recode uses 5).
help_code <- function(x, school, very_seville = 4L) case_when(
  x == "Not at all helpful" ~ 1L,
  x %in% c("Not helpful", "Slightly helpful") ~ 2L,
  x %in% c("Neutral", "Somewhat helpful") ~ 3L,
  x == "Helpful" ~ 4L,
  x == "Very helpful" ~ if_else(school == "Seville", very_seville, 5L),
  x == "Extremely helpful" ~ 5L
)  # "Other" -> NA

# ---- Statistics ---------------------------------------------------------------
tr  <- function(v) as_tibble_row(v)                                  # named vector -> one-row tibble
fml <- function(y, covs) reformulate(c("z", covs), y)                # y ~ z + covs
hc2 <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC2"))

# Treatment effect with HC2 robust CI from an lm: est, lo, hi, p
ci_hc2 <- function(m, term = "z", level = .95) {
  est <- coef(m)[term]; se <- sqrt(diag(vcovHC(m, type = "HC2")))[term]
  q <- qt(1 - (1 - level) / 2, m$df.residual)
  c(est = unname(est), lo = unname(est - q * se), hi = unname(est + q * se),
    p = unname(2 * pt(-abs(est / se), m$df.residual)))
}

# Odds ratio with Wald CI from a polr/glm fit: est, lo, hi, p
or_ci <- function(m) {
  b <- coef(m)["z"]; se <- sqrt(diag(vcov(m)))["z"]
  c(est = unname(exp(b)), lo = unname(exp(b - 1.96 * se)), hi = unname(exp(b + 1.96 * se)),
    p = unname(2 * pnorm(-abs(b / se))))
}

# Pooled effect over the three tasks from a long data frame with columns
# id, z, sev, task, y (standardised within task), zeff. Student-clustered HC2 SEs;
# also tests whether the effect differs by task.
pooled_effect <- function(long) {
  m  <- lm(y ~ z + task + sev + zeff, long)
  mi <- lm(y ~ z * task + sev + zeff, long)
  cl <- function(x) vcovCL(x, cluster = long$id, type = "HC2")
  ct <- coeftest(m, vcov = cl(m))["z", ]
  wd <- waldtest(m, mi, vcov = cl, test = "F")
  tibble(est = ct[[1]], lo = ct[[1]] - 1.96 * ct[[2]], hi = ct[[1]] + 1.96 * ct[[2]], p = ct[[4]],
         F_task_diff = wd$F[2], p_task_diff = wd$`Pr(>F)`[2])
}

# Randomisation-inference p-value: permute z within school, refit, compare.
ri_pvalue <- function(y, covs, data, B = N_PERMUTATIONS) {
  f <- fml(y, covs)
  obs <- coef(lm(f, data))["z"]
  sims <- replicate(B, { data$z <- ave(data$z, data$school, FUN = sample); coef(lm(f, data))["z"] })
  c(obs = unname(obs), p = mean(abs(sims) >= abs(obs) - 1e-12))
}

# Wilson interval for a 0/1 vector
prop_ci <- function(x) {
  w <- prop.test(sum(x), length(x), correct = FALSE)
  tibble(p = mean(x), lo = w$conf.int[1], hi = w$conf.int[2])
}

# ---- Saving results (the only code that writes to disk) ------------------------
save_table <- function(x, name) {
  path <- file.path("output", "tables", paste0(name, ".csv"))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write_csv(x, path)
  message("  wrote ", path)
  invisible(path)
}

save_figure <- function(plot, name, width = 7, height = 4.5, ext = "pdf") {
  for (e in ext) {   # e.g. ext = c("pdf", "png") for LaTeX and Word/HTML output
    path <- file.path("output", "figures", paste0(name, ".", e))
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    ggsave(path, plot, width = width, height = height, dpi = 300)
    message("  wrote ", path)
  }
  invisible(NULL)
}

read_table <- function(name) read_csv(file.path("output", "tables", paste0(name, ".csv")), show_col_types = FALSE)

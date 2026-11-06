#!/usr/bin/env Rscript
# =============================================================================
# analysis_reasoning.R
#
# Experiment 1 (AI step-by-step reasoning): tables and figures for the
# manuscript. The coin-jar task shows every student the same AI estimate
# (US$ 213; true value US$ 379.54), with or without a step-by-step explanation.
#
# The manuscript only loads the files written here and handles formatting
# (kable, captions). Nothing is computed in 03-results.Rmd for this section.
#
# Outputs
#   output/tables/reasoning_descriptives.csv   descriptive statistics by arm
#   output/figures/fig_reasoning_ecdf.pdf/.png guesses before and after the advice
#
# Usage (from the project root):
#   Rscript analysis_reasoning.R
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# ---- Paths --------------------------------------------------------------------
get_script_dir <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) == 1) {
    return(normalizePath(dirname(sub("^--file=", "", file_arg))))
  }
  normalizePath(getwd())
}
root    <- get_script_dir()
tab_dir <- file.path(root, "output", "tables")
fig_dir <- file.path(root, "output", "figures")
for (p in c(tab_dir, fig_dir)) dir.create(p, recursive = TRUE, showWarnings = FALSE)

# ---- Constants ----------------------------------------------------------------
ADVICE <- 213     # AI estimate shown to all students (US$)
TRUTH  <- 379.54  # true value of the coins in the jar (US$)
ARM_COLOURS <- c("No explanation" = "#7a7a7a", "Explanation" = "#c2410c")

# ---- Data ---------------------------------------------------------------------
# Log ratio of a guess to a reference value (relative error, symmetric in over-
# and under-estimation).
lg <- function(x, ref) log(x / ref)

raw <- readRDS(file.path(root, "analysis", "data", "processed", "tutorgpt.rds"))

d <- raw |>
  transmute(
    student_id,
    arm = factor(treatment_explain_id,
                 c("explain_no", "explain_yes"),
                 c("No explanation", "Explanation")),
    init  = q9_guess_coins_initial,
    final = q12_guess_coins_final,
    gap_final = abs(lg(final, ADVICE)),            # distance from the advice
    adopt   = as.integer(final == ADVICE),         # exact adoption
    near    = as.integer(gap_final <= log(1.10)),  # within +/-10% of the advice
    near_init = as.integer(abs(lg(init, ADVICE)) <= log(1.10)),
    err_init  = abs(lg(init,  TRUTH)),             # absolute log error
    err_final = abs(lg(final, TRUTH)),
    revised = as.integer(final != init)
  )

stopifnot(nrow(d) == 122, !anyNA(d$init), !anyNA(d$final), !anyNA(d$arm))

# ---- Table: descriptive statistics by explanation arm -------------------------
# Long format: one row per measure, one column per arm. Absolute log errors are
# multiplied by 100 (reported in hundredths of a log point, roughly percent).
measures <- tribble(
  ~group,                   ~measure,                           ~fun,
  "Sample",                 "N",                                \(x) nrow(x),
  "Belief revisions",       "Initial guess (median)",           \(x) median(x$init),
  "Belief revisions",       "Final guess (median)",             \(x) median(x$final),
  "Belief revisions",       "Revised guess (%)",                \(x) 100 * mean(x$revised),
  "Agreement with advice",  "Adopted advice exactly (%)",       \(x) 100 * mean(x$adopt),
  "Agreement with advice",  "Initial within 10% of advice (%)", \(x) 100 * mean(x$near_init),
  "Agreement with advice",  "Final within 10% of advice (%)",   \(x) 100 * mean(x$near),
  "Absolute log error",     "Initial abs. log error (median)",  \(x) 100 * median(x$err_init),
  "Absolute log error",     "Final abs. log error (median)",    \(x) 100 * median(x$err_final)
)

by_arm <- split(d, d$arm)
tab <- measures |>
  rowwise() |>
  mutate(
    `No explanation` = fun(by_arm[["No explanation"]]),
    `Explanation`    = fun(by_arm[["Explanation"]])
  ) |>
  ungroup() |>
  select(group, measure, `No explanation`, Explanation)

write.csv(tab, file.path(tab_dir, "reasoning_descriptives.csv"), row.names = FALSE)
message("  table  -> ", file.path(tab_dir, "reasoning_descriptives.csv"))

# ---- Figure: cumulative distribution of guesses, before and after -------------
fig_ecdf <- d |>
  select(student_id, arm, Before = init, After = final) |>
  pivot_longer(c(Before, After), names_to = "stage", values_to = "guess") |>
  mutate(stage = factor(stage, c("Before", "After"),
                        c("Initial guess", "Final guess (after AI estimate)"))) |>
  ggplot(aes(guess, colour = arm)) +
  stat_ecdf(linewidth = 0.9) +
  geom_vline(xintercept = ADVICE, linetype = 3) +
  geom_vline(xintercept = TRUTH,  linetype = 3) +
  annotate("text", x = ADVICE, y = 0.02, label = "AI estimate", hjust = 1.1, size = 3) +
  annotate("text", x = TRUTH,  y = 0.02, label = "True value",  hjust = -0.1, size = 3) +
  scale_x_log10(labels = scales::label_number(accuracy = 1)) +
  scale_colour_manual(values = ARM_COLOURS) +
  facet_wrap(~stage) +
  labs(x = "Guess (US$, log scale)", y = "Cumulative share of students", colour = NULL) +
  theme_classic(base_size = 11) +
  theme(legend.position = "bottom",
        strip.background = element_blank(),
        strip.text = element_text(face = "bold"))

# PDF for LaTeX output, PNG for Word / HTML output.
for (ext in c("pdf", "png")) {
  path <- file.path(fig_dir, paste0("fig_reasoning_ecdf.", ext))
  ggsave(path, fig_ecdf, width = 7, height = 3.6, dpi = 300)
  message("  figure -> ", path)
}

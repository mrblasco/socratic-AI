# 07_reasoning: Experiment 1, AI step-by-step reasoning (coin-jar task).
# Every student sees the same AI estimate (US$ 213; true value US$ 379.54), with or without a
# step-by-step explanation (randomised separately from the Socratic/non-Socratic tutor).
# The manuscript only reads these files and formats them; nothing is computed in 03-results.Rmd.
# Reads:  raw
# Writes: output/tables/reasoning_descriptives.csv, output/figures/fig_reasoning_ecdf.pdf/.png
require(dplyr)
require(ggplot2)

if (!exists("d")) { source("R/helpers.R"); source("steps/00_data.R") }

ADVICE <- 213       # AI estimate shown to all students (US$)
TRUTH  <- 379.54    # true value of the coins in the jar (US$)
ARM_COLOURS <- c("No explanation" = "#7a7a7a", "Explanation" = "#c2410c")

# Log ratio of a guess to a reference value (relative error, symmetric in over/under-estimation)
lg <- function(x, ref) log(x / ref)

rj <- d %>%
  filter(id > 1) %>% #  drop test student
  mutate(
    expl = factor(explain, c("No", "Yes"), c("No explanation", "Explanation")),
    gap_final = abs(lg(final, ADVICE)),            # distance from the advice
    adopt = as.integer(final == ADVICE),           # exact adoption
    near = as.integer(gap_final <= log(1.10)),     # final guess +/-10% advice
    near_init = as.integer(abs(lg(init, ADVICE)) <= log(1.10)),
    err_init = abs(lg(init, TRUTH)),               # absolute log error
    err_final = abs(lg(final, TRUTH)),             # final abs. log error
    revised = as.integer(final != init)            # final vs initial
  )
stopifnot(!anyNA(rj$init), !anyNA(rj$final), !anyNA(rj$expl))

# ---- Table: descriptive statistics by explanation arm -------------------------------
# One row per measure, one column per arm. Absolute log errors are multiplied by 100
# (hundredths of a log point, roughly percent).
measures <- tribble(
  ~group,                  ~measure,                           ~fun,
  "Sample",                "N",                                \(x) nrow(x),
  "Belief revisions",      "Initial guess (median)",           \(x) median(x$init),
  "Belief revisions",      "Final guess (median)",             \(x) median(x$final),
  "Belief revisions",      "Revised guess (%)",                \(x) 100 * mean(x$revised),
  "Agreement with advice", "Adopted advice exactly (%)",       \(x) 100 * mean(x$adopt),
  "Agreement with advice", "Initial within 10% of advice (%)", \(x) 100 * mean(x$near_init),
  "Agreement with advice", "Final within 10% of advice (%)",   \(x) 100 * mean(x$near),
  "Absolute log error",    "Initial abs. log error (median)",  \(x) 100 * median(x$err_init),
  "Absolute log error",    "Final abs. log error (median)",    \(x) 100 * median(x$err_final)
)
by_arm <- split(rj, rj$expl)
tab <- measures |>
  rowwise() |>
  mutate(`No explanation` = fun(by_arm[["No explanation"]]), `Explanation` = fun(by_arm[["Explanation"]])) |>
  ungroup() |>
  select(group, measure, `No explanation`, Explanation)
save_table(tab, "reasoning_descriptives")

# ---- Figure: cumulative distribution of guesses, before and after -----------------------
fig <- rj |>
  select(id, expl, Before = init, After = final) |>
  pivot_longer(c(Before, After), names_to = "stage", values_to = "guess") |>
  mutate(stage = factor(stage, c("Before", "After"), c("Initial guess", "Final guess (after AI estimate)"))) |>
  ggplot(aes(guess, colour = expl)) +
  stat_ecdf(linewidth = 0.9) +
  geom_vline(xintercept = ADVICE, linetype = 3) +
  geom_vline(xintercept = TRUTH, linetype = 3) +
  annotate("text", x = ADVICE, y = 0.02, label = "AI estimate", hjust = 1.1, size = 3) +
  annotate("text", x = TRUTH, y = 0.02, label = "True value", hjust = -0.1, size = 3) +
  scale_x_log10(labels = scales::label_number(accuracy = 1)) +
  scale_colour_manual(values = ARM_COLOURS) +
  facet_wrap(~stage) +
  labs(x = "Guess (US$, log scale)", y = "Cumulative share of students", colour = NULL) +
  theme_classic(base_size = 11) +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_text(face = "bold"))
save_figure(fig, "fig_reasoning_ecdf", width = 7, height = 3.6, ext = c("pdf", "png"))


# ----- regression

depvars <- c("adopt", "near", "err_final")
controls <- c("school", "init", "gender", "used_ai_before", "top_grades")

models <- c(
  unadjusted = sapply(depvars, reformulate, termlabels = "expl"),
  adjusted = sapply(depvars, reformulate, termlabels = c("expl", controls))
)

fits <- lapply(models, stats::lm, data = rj)

modelsummary::modelsummary(
  fits,
  stars = TRUE,
  coef_map = "explExplanation",
  gof_map = "nobs",
  vcov = "HC3",
)

coeffs <- lapply(fits, broom::tidy, conf.int = TRUE) |>
  bind_rows(.id = "model") |> 
  filter(grepl("expl", term)) |>
  mutate( 
    outcome = gsub("(.*)\\.(.*)", "\\2", model),
    specification = gsub("(.*)\\.(.*)", "\\1", model),
  ) %>%
  dplyr::select(
    outcome, specification,
    estimate, std.error,
    conf.low, conf.high, p.value
  )

coeffs %>%
  ggplot(
    aes(
      x = estimate, y = outcome, shape = specification, 
      xmin = conf.low, xmax = conf.high
    )
  ) + 
  geom_pointrange(position = position_dodge(.25)) +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed")


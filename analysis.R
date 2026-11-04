#!/usr/bin/env Rscript
# =============================================================================
# analysis.R
#
# Standalone script reproducing ALL analysis, figures, and tables from the
# manuscript "AI Chatbots in K-12 Education: An Experimental Study of Socratic
# vs. Non-Socratic Approaches".
#
# The code is ported from the manuscript R Markdown source files:
#   - 02-methods.Rmd      (Table: prompts)
#   - 03-results.Rmd      (all result figures and tables)
#   - 90-supporting.Rmd   (Table: AI step-by-step reasoning)
#   - analysis/config.R   (ggplot theme and options)
#   - docs/prespecification.md, notebooks/effect_analysis.Rmd (LLM-rated
#     student behaviour; section "RESULTS: LLM-rated ...")
#
# All artifacts (figures as PDF, tables as .txt/.csv) are written to ./output/
#
# Usage (from the project root):
#   Rscript analysis.R
# =============================================================================

# ---- Packages ---------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(ggtext)
  library(ggdist)
  library(ggrepel)
  library(knitr)
  library(kableExtra)
  library(ordinal)   # clm()
  library(MASS)      # polr(), rlm()
  library(boot)
  library(patchwork)
  library(broom)
  library(broom.mixed)
  library(lmerTest)
  library(stringr)
})

set.seed(4881)

# ---- Paths ------------------------------------------------------------------
# Resolve the project root as the directory containing this script, falling
# back to the working directory. All data paths are relative to the root.
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 1) {
    return(normalizePath(dirname(sub("^--file=", "", file_arg))))
  }
  normalizePath(getwd())
}

root     <- get_script_dir()
data_dir <- file.path(root, "analysis", "data", "processed")
out_dir  <- file.path(root, "output")
fig_dir  <- file.path(out_dir, "figures")
tab_dir  <- file.path(out_dir, "tables")
rob_dir  <- file.path(out_dir, "robustness")

for (d in c(out_dir, fig_dir, tab_dir, rob_dir)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

message("Project root : ", root)
message("Output folder: ", out_dir)

# ---- Helpers (ported from analysis/R/text_functions.R) ----------------------
wrap_text <- function(x, w = 30) {
  gsub("\n", "<br>", stringr::str_wrap(x, width = w))
}

# Shared ggplot styling for coefficient figures (from 03-results.Rmd setup)
geom_coef <- function() {
  list(
    scale_color_manual(values = c("navy", "orange")),
    geom_vline(xintercept = 0, linetype = "dashed"),
    geom_linerange(linewidth = 3, alpha = 0.2),
    geom_point(size = 3),
    guides(colour = guide_legend(position = "inside"))
  )
}

# Save a ggplot/patchwork to the figures folder as PDF.
save_fig <- function(plot, name, width = 7, height = 5) {
  path <- file.path(fig_dir, paste0(name, ".pdf"))
  ggsave(path, plot = plot, width = width, height = height, device = "pdf")
  message("  figure -> ", path)
}

# Save a table (data.frame/matrix/table) to a .txt (pretty) and a .csv file.
save_table <- function(x, name, caption = NULL, digits = 1) {
  txt_path <- file.path(tab_dir, paste0(name, ".txt"))
  csv_path <- file.path(tab_dir, paste0(name, ".csv"))
  con <- file(txt_path, open = "wt")
  if (!is.null(caption)) {
    writeLines(caption, con)
    writeLines(strrep("-", nchar(caption)), con)
  }
  writeLines(knitr::kable(x, format = "pipe", digits = digits), con)
  close(con)
  df <- tryCatch(as.data.frame(x), error = function(e) NULL)
  if (!is.null(df)) {
    utils::write.csv(df, csv_path, row.names = TRUE)
  }
  message("  table  -> ", txt_path)
}

# Write a table/text into an arbitrary directory (used by the robustness block).
save_table_to <- function(x, dir, name, caption = NULL, digits = 3) {
  txt_path <- file.path(dir, paste0(name, ".txt"))
  csv_path <- file.path(dir, paste0(name, ".csv"))
  con <- file(txt_path, open = "wt")
  if (!is.null(caption)) {
    writeLines(caption, con)
    writeLines(strrep("-", nchar(caption)), con)
  }
  writeLines(knitr::kable(x, format = "pipe", digits = digits), con)
  close(con)
  df <- tryCatch(as.data.frame(x), error = function(e) NULL)
  if (!is.null(df)) utils::write.csv(df, csv_path, row.names = TRUE)
  message("  robustness table  -> ", txt_path)
}

# Capture arbitrary console output (model summaries, tests) into the robustness dir.
save_text_to <- function(expr, dir, name) {
  path <- file.path(dir, paste0(name, ".txt"))
  capture.output(expr, file = path)
  message("  robustness text   -> ", path)
}

save_fig_to <- function(plot, dir, name, width = 7, height = 5) {
  path <- file.path(dir, paste0(name, ".pdf"))
  ggsave(path, plot = plot, width = width, height = height, device = "pdf")
  message("  robustness figure -> ", path)
}

# ---- ggplot theme / options (ported from analysis/config.R) -----------------
options(
  knitr.table.toprule = "\\toprule",
  knitr.table.midrule = "\\midrule\\arrayrulecolor{gray!20}",
  knitr.table.bottomrule = "\\arrayrulecolor{black}\\bottomrule"
)

theme_set(theme_classic())
theme_update(
  plot.title    = element_markdown(face = "bold", lineheight = 1.3),
  plot.subtitle = element_markdown(face = "italic", lineheight = 1.3),
  strip.background = element_blank(),
  strip.text    = element_markdown(size = 11, lineheight = 1.2, face = "bold")
)

# ---- Load processed data ----------------------------------------------------
tutorgpt      <- readRDS(file.path(data_dir, "tutorgpt.rds"))
chats         <- readRDS(file.path(data_dir, "chats.rds"))
tutorgpt_wide <- readRDS(file.path(data_dir, "tutorgpt_wide.rds"))

# =============================================================================
# METHODS: Table of prompt instructions (chunk `prompts` in 02-methods.Rmd)
# =============================================================================
message("\n[Methods] Table: prompt instructions")
df_prompts <- data.frame(
  "AI Tutor" = c("Socratic", "Non-Socratic"),
  "Prompt instruction" = c(
    "You are a Socratic tutor. You always answer using the Socratic style, asking just the right questions to help students learn to think for themselves and breaking down the problem into simpler parts until it's at the right level for them. You provide concise information and explanations understandable for 8th to 10th grade students.",
    "You are a didactic tutor. You provide concise information and explanations understandable for 8th to 10th grade students."
  ),
  check.names = FALSE
)
save_table(df_prompts, "methods_tab_prompts",
           caption = "Prompt instructions associated with the AI Tutor's treatments")

# =============================================================================
# RESULTS
# =============================================================================

# -----------------------------------------------------------------------------
# Table: Sample characteristics (chunk `summary-statistics`)
# -----------------------------------------------------------------------------
message("\n[Results] Table: sample characteristics")
tutorgpt_rename <- tutorgpt %>%
  dplyr::select(
    treatment_tutor_id,
    treatment_explain_id,
    "Gender" = gender,
    "Has used ChatGPT" = has_used_before,
    "Location" = location,
    "Grades" = top_grades,
    "Homework weekly study" = hours_per_week,
    "Homework on time" = on_time_completion,
    "Homework difficulties" = factors_contributing,
    "Self-efficacy (sound)" = q5_self_physics,
    "Self-efficacy (essay)" = q6_self_technology,
    "Self-efficacy (guess)" = q7_self_swimming_pool
  )

table_socratic <- tutorgpt_rename %>%
  dplyr::select(-treatment_explain_id) %>%
  tidyr::pivot_longer(-treatment_tutor_id) %>%
  dplyr::mutate(pval = xtabs(~ value + treatment_tutor_id) %>%
                  fisher.test() %>%
                  .$p.value,
                .by = name) %>%
  dplyr::count(name, value, pval, treatment_tutor_id) %>%
  na.omit() %>%
  dplyr::mutate(percent = 100 * n / sum(n),
                .by = c(name, treatment_tutor_id)) %>%
  tidyr::pivot_wider(names_from = treatment_tutor_id,
                     values_from = c(percent, n),
                     values_fill = 0) %>%
  dplyr::mutate(totals = n_non_socratic + n_socratic)

table_explain <- tutorgpt_rename %>%
  dplyr::select(-treatment_tutor_id) %>%
  tidyr::pivot_longer(-treatment_explain_id) %>%
  dplyr::mutate(pval_explain = xtabs(~ value + treatment_explain_id) %>%
                  fisher.test() %>%
                  .$p.value,
                .by = name) %>%
  dplyr::count(name, value, treatment_explain_id, pval_explain) %>%
  na.omit() %>%
  dplyr::mutate(percent = 100 * n / sum(n),
                .by = c(name, treatment_explain_id)) %>%
  tidyr::pivot_wider(names_from = treatment_explain_id,
                     values_from = c(percent, n),
                     values_fill = 0)

summary_statistics <- table_socratic %>%
  dplyr::left_join(table_explain, by = c("name", "value")) %>%
  dplyr::mutate(name = ifelse(row_number() == 1, name, ""),
                pval = ifelse(row_number() == 1, sprintf("%0.2f", pval), ""),
                pval_explain = ifelse(row_number() == 1, sprintf("%0.2f", pval_explain), ""),
                .by = name) %>%
  dplyr::select(
    name, value,
    percent_socratic, percent_non_socratic, pval,
    percent_explain_yes, percent_explain_no, pval_explain,
    totals
  )
save_table(summary_statistics, "tab_summary_statistics",
           caption = "Sample Characteristics (percent within treatment; Fisher's exact p-values)",
           digits = 0)

# -----------------------------------------------------------------------------
# Figure: Attitudes towards AI (chunk `attitudes-AI`)
# -----------------------------------------------------------------------------
message("\n[Results] Figure: attitudes towards AI")
agree_labels <- c(
  strongly_agree = "S-Agree",
  agree = "Agree",
  neutral = "Neutral",
  disagree = "Disagree",
  strongly_disagree = "S-Disagree"
)
palette <- c("#ca0020", "#f4a582", "#d1e5f0", "#92c5de", "#0571b0")

attitudes_df <- tutorgpt %>%
  dplyr::select(
    "Society will benefit from a future of AI?" = q1_ai_future,
    "AI is dangerous" = q2_ai_danger,
    "AI is often misused by students" = q4_ai_misuse,
    "AI will foster students' learning in the future" = q3_ai_learning
  ) %>%
  tidyr::pivot_longer(cols = everything()) %>%
  dplyr::count(name, value) %>%
  dplyr::mutate(percent = 100 * (n + 1) / (sum(n) + 5), .by = name)

p_attitudes <- attitudes_df %>%
  ggplot() +
  aes(
    x = percent,
    y = factor(value, levels = names(agree_labels)),
    label = paste0(round(percent), "%"),
    fill = factor(value, levels = names(agree_labels))
  ) +
  geom_col(width = 0.8, show.legend = FALSE) +
  geom_text(aes(hjust = ifelse(percent < 5, -0.5, 0.5)),
            position = position_stack(vjust = 0.5)) +
  facet_wrap(~ wrap_text(name), scales = "free") +
  scale_y_discrete(labels = agree_labels) +
  scale_fill_manual(values = rev(palette)) +
  theme(
    axis.line.x = element_blank(),
    axis.ticks = element_blank(),
    axis.text.x = element_blank(),
    panel.spacing = unit(2, "lines")
  ) +
  labs(
    x = NULL, y = NULL,
    caption = "Source: Full sample (n = 122)",
    title = "Student Attitudes on AI in Education",
    subtitle = "% of students who agree or disagree with the statement:"
  )
save_fig(p_attitudes, "fig_attitudes_AI", width = 8, height = 6)

# -----------------------------------------------------------------------------
# AI step-by-step reasoning: update propensity (chunk `update-propensity`)
# -----------------------------------------------------------------------------
message("\n[Results] Update propensity (table + model + figure)")
update_ds <- tutorgpt %>%
  dplyr::mutate(update = sign(q12_guess_coins_final - q9_guess_coins_initial),
                initial_guess_100 = q9_guess_coins_initial / 100)

update_propensity_table <- update_ds %>%
  xtabs(formula = ~ update + treatment_explain_id)
save_table(update_propensity_table, "tab_update_propensity",
           caption = "Direction of guess update by AI-explanation treatment", digits = 0)

fisher_update <- fisher.test(update_propensity_table)
capture.output(
  {
    cat("Fisher's exact test: update direction vs AI-explanation treatment\n")
    print(fisher_update)
  },
  file = file.path(tab_dir, "test_update_propensity_fisher.txt")
)

# util functions (local to this chunk)
center  <- function(x) scale(x, center = TRUE, scale = FALSE)
topcode <- function(x, value) ifelse(x > value, value, x)

model <- center(q12_guess_coins_final) ~ initial_guess_100 +
  I(initial_guess_100^2) + treatment_explain_id + location

fit_update_propensity <- lm(model, update_ds)
fit_robust <- MASS::rlm(model, update_ds)
fit_no_out <- update(fit_robust, subset = q9_guess_coins_initial < 1e5)

fit <- list(fit_update_propensity, fit_robust, fit_no_out)
capture.output(
  stargazer::stargazer(fit, type = "text", keep.stat = "n", digits = 1),
  file = file.path(tab_dir, "tab_update_propensity_regressions.txt")
)

p_update <- tutorgpt %>%
  dplyr::mutate(
    final_tc   = topcode(q12_guess_coins_final, 1e3),
    initial_tc = topcode(q9_guess_coins_initial, 1e3)
  ) %>%
  ggplot(aes(x = initial_tc, y = final_tc,
             color = treatment_explain_id,
             pch = treatment_explain_id,
             fill = treatment_explain_id,
             linetype = treatment_explain_id)) +
  geom_point() +
  geom_smooth(alpha = .25) +
  labs(x = "First Guess ($)", y = "Second Guess ($)") +
  theme(legend.position = "bottom")
save_fig(p_update, "fig_update_propensity", width = 7, height = 5)

# -----------------------------------------------------------------------------
# Figure: Bootstrap accuracy (chunk `boot-accuracy`)
# -----------------------------------------------------------------------------
message("\n[Results] Figure: bootstrap accuracy")
coins_value <- 379.54
n_boot <- 1999
palette <- c("#d95f02", "#7570b3")

resample_median <- function(n_boot, x) {
  mat <- replicate(n_boot, sample(x, replace = TRUE))
  apply(mat, 2, median)
}

bootstrap_accuracy <- tutorgpt %>%
  dplyr::filter(q12_guess_coins_final < 6e3) %>%
  dplyr::mutate(abs_err = abs(q12_guess_coins_final - coins_value)) %>%
  dplyr::reframe(
    .by = treatment_explain_id,
    boot_med = resample_median(n_boot, abs_err),
    sim_id = seq(n_boot)
  )

bootstrap_accuracy_diff <- bootstrap_accuracy %>%
  dplyr::summarise(diff = diff(boot_med), .by = sim_id)

alpha <- 0.1
diff_cis <- bootstrap_accuracy_diff %>%
  dplyr::reframe(quantile(diff, p = c(alpha / 2, 1 - alpha / 2)))

p_value <- bootstrap_accuracy_diff %>%
  with(1 - (sum(diff < 0) + 1) / (length(diff) + 2))
p_value_one_sided <- bootstrap_accuracy_diff %>%
  with(mean(diff > 0))

capture.output(
  {
    cat("Bootstrap median absolute error difference (AI reasoning vs control)\n")
    cat(sprintf("90%% CI for difference: [%0.2f, %0.2f]\n",
                diff_cis[[1]][1], diff_cis[[1]][2]))
    cat(sprintf("two-sided p.value   = %0.4f\n", p_value))
    cat(sprintf("one-sided p.value   = %0.4f\n", p_value_one_sided))
  },
  file = file.path(tab_dir, "test_bootstrap_accuracy.txt")
)

p_dens_diff <- bootstrap_accuracy_diff %>%
  ggplot() +
  aes(x = diff) +
  geom_density(alpha = .4, bw = "sj", fill = "lightgray") +
  labs(x = "Difference in Median Absolute Error", y = "Density") +
  scale_fill_manual(values = palette) +
  scale_color_manual(values = palette) +
  theme(
    axis.text.y = element_blank(), axis.ticks.y = element_blank(),
    legend.position = "top", legend.title = element_blank()
  ) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  annotate("text", x = -35, y = 0.015, color = palette[2],
           label = sprintf("Bootstrapped median difference\np.value = %0.3f", p_value))

p_dens <- bootstrap_accuracy %>%
  ggplot() +
  aes(x = boot_med, fill = treatment_explain_id, color = treatment_explain_id) +
  geom_density(alpha = 0.4, bw = "nrd") +
  labs(x = "Median Absolute Error", y = "Density (bootstrap)") +
  scale_fill_manual(values = palette) +
  scale_color_manual(values = palette) +
  theme(
    axis.text.y = element_blank(), axis.ticks.y = element_blank(),
    legend.position = "top", legend.title = element_blank()
  )

p_boot <- (p_dens + p_dens_diff) +
  plot_annotation(
    tag_levels = "A",
    caption = "Source: Full sample (N = 121, excluding one outlier)."
  )
save_fig(p_boot, "fig_boot_accuracy", width = 7, height = 3)

# -----------------------------------------------------------------------------
# Tables: perceived accuracy of AI and human guesses (hidden chunks)
# -----------------------------------------------------------------------------
message("\n[Results] Tables: perceived accuracy AI/human")
xtab_ai <- xtabs(~ q10_guess_coins_ai_accuracy + treatment_explain_id, tutorgpt)
save_table(prop.table(addmargins(xtab_ai, 2), margin = 2) * 100,
           "tab_perceived_accuracy_ai",
           caption = "% of students who perceived the AI-generated coin estimate accuracy",
           digits = 0)

xtab_human <- xtabs(~ q11_guess_coins_human_accuracy + treatment_explain_id, tutorgpt)
save_table(prop.table(xtab_human, margin = 2) * 100,
           "tab_perceived_accuracy_human",
           caption = "% of students who perceived the human-generated average guess accuracy",
           digits = 0)

# -----------------------------------------------------------------------------
# Figure: perceived accuracy coins regression (chunk `perceived-accuracy-coins`)
# -----------------------------------------------------------------------------
message("\n[Results] Figure: perceived accuracy coins (ordinal logit)")
reverse_order <- function(x) factor(x, rev(levels(x)), ordered = TRUE)

model <- reverse_order(q11_guess_coins_human_accuracy) ~ treatment_explain_id +
  location + has_used_before + gender

fit    <- MASS::polr(model, tutorgpt)
fit_ai <- update(fit, reverse_order(q10_guess_coins_ai_accuracy) ~ .)

perceived_coef <- list("Human" = fit, "AI" = fit_ai) %>%
  lapply(broom::tidy, conf.int = TRUE) %>%
  dplyr::bind_rows(.id = "depvar") %>%
  dplyr::filter(term == "treatment_explain_idexplain_yes")

save_table(perceived_coef, "tab_perceived_accuracy_coins_coefs",
           caption = "Ordinal logit coefficient of AI-reasoning on perceived accuracy",
           digits = 3)

p_perceived <- perceived_coef %>%
  ggplot() +
  aes(color = "95% CI", x = estimate, y = depvar,
      xmin = conf.low, xmax = conf.high) +
  scale_y_discrete(labels = c(Human = "Perceived human accuracy",
                              AI = "Perceived AI accuracy")) +
  scale_color_manual(values = "navy") +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_linerange(linewidth = 3, alpha = 0.2) +
  geom_point(size = 3) +
  guides(colour = guide_legend(position = "inside")) +
  theme(legend.position.inside = c(0.1, 0.9), legend.title = element_blank()) +
  labs(x = "Regression coefficient (ordinal logistic)", y = "Dep. var.")
save_fig(p_perceived, "fig_perceived_accuracy_coins", width = 7, height = 3.5)

# -----------------------------------------------------------------------------
# Figure: messages / word counts (chunk `messages`)
# -----------------------------------------------------------------------------
message("\n[Results] Figure: messages and word counts")
palette <- c("#d95f02", "#7570b3")

messages <- chats %>%
  dplyr::filter(!is.na(created_at)) %>%
  dplyr::count(location, user_id, treatment_tutor_id, sort = TRUE)

# Wilcoxon test on number of messages
wilcox_messages <- wilcox.test(n ~ treatment_tutor_id, data = messages)
# Wilcoxon test on word counts
wilcox_words <- wilcox.test(words ~ treatment_tutor_id, data = chats)
capture.output(
  {
    cat("Wilcoxon test: messages exchanged by Socratic vs non-Socratic\n")
    print(wilcox_messages)
    cat("\nWilcoxon test: word counts by Socratic vs non-Socratic\n")
    print(wilcox_words)
  },
  file = file.path(tab_dir, "test_messages_wilcoxon.txt")
)

df_med_messages <- messages %>%
  dplyr::summarise(n = median(n), .by = c(treatment_tutor_id)) %>%
  dplyr::mutate(label = dplyr::case_when(
    treatment_tutor_id == "socratic" ~ paste0("Socratic median exchanges = ", n),
    TRUE ~ paste0("Non-Socratic median exchanges = ", n)
  ))

df_med_words <- chats %>%
  dplyr::summarise(words = median(words), .by = c(treatment_tutor_id, role_label)) %>%
  dplyr::mutate(label = dplyr::case_when(
    treatment_tutor_id == "socratic" ~ paste0("Socratic med. words = ", words),
    TRUE ~ paste0("Non-Socratic med. words = ", words)
  ))

p_messages <- ggplot(messages) +
  aes(x = n, y = treatment_tutor_id,
      color = treatment_tutor_id, fill = treatment_tutor_id) +
  geom_boxplot(width = .15, fill = "whitesmoke", outlier.shape = NA) +
  ggdist::stat_halfeye(adjust = .75, alpha = .25, width = 1,
                       justification = -.2, point_colour = NA, point_interval = NULL) +
  geom_point(size = .75, alpha = .5,
             position = position_jitter(width = .05, height = 0.05)) +
  geom_text(data = df_med_messages, nudge_y = .25,
            aes(label = label), size = 3, fontface = "bold") +
  scale_y_discrete(labels = c(socratic = "Socratic", non_socratic = "Non-Socratic")) +
  scale_x_log10() +
  scale_fill_manual(values = palette) +
  scale_color_manual(values = palette) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        legend.position = "none", panel.spacing = unit(3, "lines"))

p_words <- chats %>%
  ggplot() +
  aes(x = words, y = treatment_tutor_id,
      color = treatment_tutor_id, fill = treatment_tutor_id) +
  geom_boxplot(width = .15, fill = "whitesmoke", outlier.shape = NA) +
  ggdist::stat_halfeye(alpha = .25, width = .5, .width = 0,
                       justification = -.2, point_colour = NA, point_interval = NULL) +
  geom_point(size = .15, alpha = .3,
             position = position_jitter(width = .05, height = 0.05)) +
  geom_text(data = df_med_words, nudge_y = .25,
            aes(label = label), size = 3, fontface = "bold") +
  facet_wrap(. ~ role_label) +
  scale_color_manual(values = palette) +
  scale_fill_manual(values = palette) +
  scale_y_discrete(labels = c(socratic = "Socratic", non_socratic = "Non-Socratic")) +
  scale_x_log10() +
  theme(legend.position = "none", panel.spacing = unit(3, "lines"),
        axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  coord_cartesian(clip = FALSE)

p_combined <-
  (p_messages + labs(title = NULL, subtitle = NULL, caption = NULL,
                     x = "Messages Exchanged with AI Tutor (per student)", y = NULL)) /
  (p_words + labs(title = NULL, subtitle = NULL, caption = NULL,
                  y = NULL, x = "Word Counts (per message)"))

p_messages_fig <- p_combined + plot_annotation(tag_levels = "A")
save_fig(p_messages_fig, "fig_messages", width = 7, height = 7)

# -----------------------------------------------------------------------------
# Confidence & helpfulness distribution figures (chunks `confidence`,`helpfulness`)
# Shared helper create_impact_figure()
# -----------------------------------------------------------------------------
message("\n[Results] Figures: confidence & helpfulness distributions")
create_impact_figure <- function(data, measure) {
  data_long <- data %>%
    dplyr::bind_rows(dplyr::mutate(data, name = "All")) %>%
    xtabs(
      formula = as.formula(paste("~", measure, "+ treatment_tutor_id + name")),
      data = .,
      exclude = "Other"
    )

  test_results <- apply(data_long, 3, fisher.test)
  p_values <- sapply(test_results, function(x) x$p.value)

  plot_df <- as.data.frame(data_long) %>%
    dplyr::mutate(percent = 100 * (Freq + 1) / (sum(Freq) + 5),
                  .by = c(treatment_tutor_id, name)) %>%
    dplyr::mutate(
      treatment_tutor_id = dplyr::case_when(
        treatment_tutor_id == "socratic" ~ "Socratic AI",
        TRUE ~ "Non-Socratic AI"
      ),
      name = dplyr::case_match(name,
        "All" ~ sprintf("All tasks<br>p = %2.3f", p_values["All"]),
        "task1_water" ~ sprintf("Task 1: Guess<br>p = %2.3f", p_values["task1_water"]),
        "task2_media" ~ sprintf("Task 2: Essay<br>p = %2.3f", p_values["task2_media"]),
        "task3_sound" ~ sprintf("Task 3: Physics<br>p = %2.3f", p_values["task3_sound"])
      )
    )

  palette <- c("#ca0020", "#f4a582", "#d1e5f0", "#92c5de", "#0571b0")

  ggplot(plot_df) +
    aes(x = percent, label = paste0(round(percent), "%"),
        y = get(measure),
        hjust = ifelse(percent < 5, -1, 0),
        fill = get(measure),
        position = name) +
    facet_grid(name ~ treatment_tutor_id, scales = "free") +
    scale_fill_manual(values = palette) +
    geom_col(width = .8, show.legend = FALSE, position = position_dodge(1), alpha = .75) +
    geom_text(position = position_stack(.5)) +
    theme(
      axis.line.x = element_blank(),
      axis.ticks = element_blank(),
      axis.text.x = element_blank(),
      strip.text.y = ggtext::element_markdown(face = "plain"),
      panel.spacing = unit(2, "lines")
    ) +
    labs(x = NULL, y = NULL,
         caption = "Source: Full sample of student-task combinations (n = 364)")
}

# Invert confidence levels (as in the manuscript)
tutorgpt_wide <- tutorgpt_wide %>%
  dplyr::mutate(value = factor(value, rev(levels(value))))

p_confidence <- create_impact_figure(data = tutorgpt_wide, measure = "value")
save_fig(p_confidence, "fig_confidence", width = 7, height = 7)

p_helpfulness <- create_impact_figure(data = tutorgpt_wide, measure = "helpful")
save_fig(p_helpfulness, "fig_helpfulness", width = 7, height = 7)

# -----------------------------------------------------------------------------
# Figure: confidence regression (chunk `confidence-regression`)
# -----------------------------------------------------------------------------
message("\n[Results] Figure: confidence regression (clm)")
fit_all <- ordinal::clm(
  value ~ treatment_tutor_id + name + conf_value, data = tutorgpt_wide
)
fit_task_1 <- ordinal::clm(
  value ~ treatment_tutor_id + conf_value + location,
  data = tutorgpt_wide, subset = name == "task1_water"
)
fit_task_2 <- ordinal::clm(
  value ~ treatment_tutor_id + location + gender + has_used_before,
  data = tutorgpt_wide, subset = name == "task2_media"
)
fit_task_3 <- ordinal::clm(
  value ~ treatment_tutor_id + conf_value + location,
  data = tutorgpt_wide, subset = name == "task3_sound"
)

df_coef <- list(all = fit_all, task1 = fit_task_1,
                task2 = fit_task_2, task3 = fit_task_3) %>%
  lapply(broom::tidy, conf.int = TRUE) %>%
  dplyr::bind_rows(.id = "name")

save_table(dplyr::filter(df_coef, grepl("treat", term)),
           "tab_confidence_regression_coefs",
           caption = "Ordinal logit (clm) treatment coefficients on confidence",
           digits = 3)

p_conf_reg <- df_coef %>%
  dplyr::filter(grepl("treat", term)) %>%
  ggplot() +
  aes(color = "95% CI", x = estimate, y = name,
      xmin = conf.low, xmax = conf.high) +
  geom_coef() +
  scale_y_discrete(labels = c(task1 = "Task 1 (guessing)",
                              task2 = "Task 2 (writing)",
                              task3 = "Task 3 (physics)",
                              all = "All tasks")) +
  theme(legend.position.inside = c(.1, .9), legend.title = element_blank(),
        plot.title.position = "plot") +
  labs(x = "Regression coefficient (ordinal logistic)", y = "Tasks")
save_fig(p_conf_reg, "fig_confidence_regression", width = 7, height = 4)

# -----------------------------------------------------------------------------
# Figure: helpful regression (chunk `helpful-regression`)
# -----------------------------------------------------------------------------
message("\n[Results] Figure: helpfulness regression (polr)")
fit_all    <- MASS::polr(helpful ~ treatment_tutor_id + name, tutorgpt_wide)
fit_task_1 <- MASS::polr(helpful ~ treatment_tutor_id, tutorgpt_wide, subset = name == "task1_water")
fit_task_2 <- MASS::polr(helpful ~ treatment_tutor_id, tutorgpt_wide, subset = name == "task2_media")
fit_task_3 <- MASS::polr(helpful ~ treatment_tutor_id, tutorgpt_wide, subset = name == "task3_sound")

df_coef <- list(all = fit_all, task1 = fit_task_1,
                task2 = fit_task_2, task3 = fit_task_3) %>%
  lapply(broom::tidy, conf.int = TRUE) %>%
  dplyr::bind_rows(.id = "name")

save_table(dplyr::filter(df_coef, grepl("treat", term)),
           "tab_helpful_regression_coefs",
           caption = "Ordinal logit (polr) treatment coefficients on helpfulness",
           digits = 3)

p_help_reg <- df_coef %>%
  dplyr::filter(grepl("treat", term)) %>%
  ggplot() +
  aes(color = "95% CI", x = estimate, y = name,
      xmin = conf.low, xmax = conf.high) +
  geom_coef() +
  scale_y_discrete(labels = c(task1 = "Task 1 (guessing)",
                              task2 = "Task 2 (writing)",
                              task3 = "Task 3 (sound propagation)",
                              all = "All tasks")) +
  theme(legend.position.inside = c(.1, .9), legend.title = element_blank(),
        plot.title.position = "plot") +
  labs(x = "Regression coefficient (ordinal logistic)", y = "Sample",
       title = "Effect of Socratic AI on Students' Perceived Helpfulness of the AI Tutor")
save_fig(p_help_reg, "fig_helpful_regression", width = 7, height = 4)

# -----------------------------------------------------------------------------
# Learning outcomes & retention (chunk `learning`)
# -----------------------------------------------------------------------------
message("\n[Results] Learning outcomes and retention (table + figure)")
tutorgpt <- tutorgpt %>%
  dplyr::mutate(
    q29_sound_speed_verify = dplyr::case_match(
      q29_sound_speed_verify,
      c("0", "very_helpful") ~ "Rubber",
      c("helpful", "1", "2") ~ "Warm/Cold Air",
      c("3", "neutral") ~ "Gold",
      c("4", "not_very_helpful") ~ "Water",
      .default = q29_sound_speed_verify
    )
  )

tab <- tutorgpt %>%
  dplyr::bind_rows(., dplyr::mutate(., treatment_tutor_id = "All")) %>%
  xtabs(~ q25_sound_speed + treatment_tutor_id, .) %>%
  prop.table(2) * 100

colnames(tab) <- dplyr::case_match(colnames(tab),
  "All" ~ "Full sample", "socratic" ~ "Socratic AI", "non_socratic" ~ "Non-Socratic")
rownames(tab) <- dplyr::case_match(rownames(tab),
  "same_speed" ~ "Same speed",
  "water_faster_higher_density" ~ "Water is faster because higher density (correct)",
  "water_faster_lower_density" ~ "Water is faster because lower density",
  "water_slower_higher_density" ~ "Water is slower because higher density",
  "water_slower_lower_density" ~ "Water is slower because lower density",
  .default = rownames(tab))
save_table(tab, "tab_sound_speed_responses",
           caption = "% of students by responses to 'Does sound travel faster in water than air?'",
           digits = 1)

tutorgpt <- tutorgpt %>%
  dplyr::mutate(
    q25_sound_speed_correct = ifelse(
      q25_sound_speed == "water_faster_higher_density", "correct", "incorrect"),
    q26_sound_speed_with_ai_correct = ifelse(
      q26_sound_speed_with_ai == "water_faster_higher_density", "correct", "incorrect"),
    q26_update = ifelse(
      q25_sound_speed != q26_sound_speed_with_ai, "update_yes", "update_no")
  )

strip_labels <- c(
  "(Intercept)" = "Non-Socratic AI",
  "treatment_tutor_idsocratic" = "Diff. with Socratic AI"
)

panel_a <- tutorgpt %>%
  tidyr::pivot_longer(c(q25_sound_speed_correct, q26_sound_speed_with_ai_correct)) %>%
  dplyr::reframe(
    broom::tidy(lm(value == "correct" ~ treatment_tutor_id), conf.int = TRUE), .by = name
  ) %>%
  dplyr::mutate(
    name = dplyr::case_match(name,
      "q25_sound_speed_correct" ~ "Before AI",
      "q26_sound_speed_with_ai_correct" ~ "After AI")
  ) %>%
  ggplot() +
  aes(x = estimate, y = name, xmin = conf.low, xmax = conf.high, color = "95% CI") +
  facet_grid(~ term, labeller = labeller(term = strip_labels)) +
  geom_coef() +
  geom_text_repel(aes(label = paste0(round(estimate * 100), "%"))) +
  theme(legend.position = "none", panel.spacing = unit(3, "lines")) +
  scale_x_continuous(labels = function(x) 100 * x) +
  labs(x = "Correct answers (%)", y = NULL,
       title = "Impact of AI on Answer Accuracy",
       subtitle = "Comparison of Correct Answers Before and After Interacting with AI Tutor")

water <- data.frame(
  q29_sound_speed_verify = c("Gold", "Water", "Warm/Cold Air", "Rubber"),
  speed = c(3200, 1500, 350, 60) / 1e3
)

panel_b_data <- tutorgpt %>%
  xtabs(~ q29_sound_speed_verify, .) %>%
  as.data.frame() %>%
  dplyr::left_join(water, by = "q29_sound_speed_verify") %>%
  dplyr::mutate(
    percent = 100 * (Freq + 1) / (sum(Freq) + 4),
    name = sprintf("%s<br>(%.1f km/s)", q29_sound_speed_verify, speed)
  )

panel_b <- panel_b_data %>%
  ggplot() +
  aes(x = percent, y = reorder(q29_sound_speed_verify, speed),
      label = paste0(round(percent), "%"),
      hjust = ifelse(percent > 10, 1.2, -.2)) +
  geom_col(fill = "orange") +
  geom_text() +
  geom_text(aes(label = sprintf("%.1f m/s", speed)), x = 0, hjust = 0, color = "white") +
  theme(axis.text.y = element_markdown(lineheight = 1.3, hjust = 0)) +
  labs(x = "Students (%)", y = NULL)

p_learning <- (panel_a + labs(title = NULL, subtitle = NULL)) / (panel_b) +
  plot_annotation(tag_levels = "A")
save_fig(p_learning, "fig_learning", width = 7, height = 7)

# -----------------------------------------------------------------------------
# Figure: interaction effects (chunk `interactions`)
# -----------------------------------------------------------------------------
message("\n[Results] Figure: interaction effects (mixed models)")
tutorgpt_wide <- tutorgpt_wide %>%
  dplyr::mutate(
    helpful_yes   = helpful %in% c("Helpful", "Very helpful"),
    confident_yes = value %in% c("Very confident", "Confident")
  )

calc_stars <- function(p.value) {
  dplyr::case_when(
    p.value < 0.01 ~ "***",
    (p.value < 0.05 & p.value > 0.01) ~ "**",
    (p.value < 0.1 & p.value > 0.05) ~ "*",
    TRUE ~ ""
  )
}

build_interaction_panel <- function(dv, title, subtitle) {
  fit_lmer <- lmerTest::lmer(
    as.formula(paste0(
      "100 * ", dv, " ~ treatment_tutor_id + name + conf_value + location + ",
      "gender + has_used_before + top_grades + (1 | student_id)"
    )),
    tutorgpt_wide
  )

  interactions <- list(baseline = fit_lmer)
  interactions$used   <- update(fit_lmer, ~ . + treatment_tutor_id:has_used_before)
  interactions$name   <- update(fit_lmer, ~ . + treatment_tutor_id:name)
  interactions$gender <- update(fit_lmer, ~ . + treatment_tutor_id:gender)
  interactions$grades <- update(fit_lmer, ~ . + treatment_tutor_id:top_grades)
  interactions$all    <- update(fit_lmer, ~ . + treatment_tutor_id:(
    has_used_before + top_grades + gender + location + name))

  coef_df <- interactions %>%
    lapply(broom.mixed::tidy, conf.int = TRUE) %>%
    dplyr::bind_rows(.id = "model")

  coef_df %>%
    dplyr::filter(grepl(":", term), model == "all") %>%
    ggplot() +
    aes(x = estimate, y = term, xmin = conf.low, xmax = conf.high,
        color = p.value < 0.1) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_linerange(linewidth = 3, alpha = .25) +
    geom_point(size = 3) +
    geom_text_repel(nudge_y = -.25,
                    aes(label = sprintf("%.1f%s", estimate, calc_stars(p.value)))) +
    geom_text(x = Inf,
              aes(label = sprintf("(%s: %.1f, %.1f)", "95% CI", conf.low, conf.high)),
              size = 3.5) +
    coord_cartesian(clip = "off") +
    theme(legend.position = "none",
          axis.text.y = element_markdown(hjust = 0),
          plot.margin = margin(t = .1, b = .1, r = 1, l = .1, unit = "in")) +
    scale_color_manual(values = c("orange", "navy")) +
    scale_y_discrete(labels = function(x) {
      x %>%
        gsub("^.*:", "Socratic x ", .) %>%
        gsub("has_used_beforeYes", "ChatGPT experience", .) %>%
        gsub("locationSeville", "Seville", .) %>%
        gsub("top_grades", "", .) %>%
        gsub("gender", "", .) %>%
        gsub("nametask([123])_(.*)", "Task \\1 (\\2)", .)
    }) +
    labs(title = title, subtitle = subtitle, y = NULL,
         x = "Regression coefficients and 95% confidence intervals",
         caption = "Results from linear regression (n = 366); * p < 0.1")
}

panel_a <- build_interaction_panel(
  "confident_yes",
  "Socratic AI and Student Confidence Levels",
  "Interaction effects between Socratic AI and task/student characteristics")

panel_b <- build_interaction_panel(
  "helpful_yes",
  "Socratic AI and Perceived Helpfulness",
  "Interaction effects between Socratic AI and task/student characteristics")

p_interactions <- panel_a / panel_b + plot_annotation(tag_levels = "A")
save_fig(p_interactions, "fig_interactions", width = 8, height = 10)

# =============================================================================
# SUPPORTING INFORMATION
# =============================================================================

# -----------------------------------------------------------------------------
# Table: AI step-by-step reasoning (chunk `explanation` in 90-supporting.Rmd)
# -----------------------------------------------------------------------------
message("\n[Supporting] Table: AI step-by-step reasoning")
df_reasoning <- data.frame(
  Step = c("Introduction", "Estimate the volume of the jar",
           "Estimate the volume of a single coin", "Convert to dollars"),
  Explanation = c(
    "To estimate the total value of the coins in the jar, let's go through a step-by-step process.",
    "The jar in the image resembles a standard large water bottle, possibly around 5 gallons (18.93 liters) in volume. Since the coins don't fill the jar completely, we estimate they occupy about 1/4 of the jar. Therefore, the volume filled by coins is approximately 1.25 gallons or about 4.73 liters.",
    "Assuming most coins are US pennies, with a volume of around 0.36 cubic centimeters, we need to determine how many pennies could fit into the 4.73-liter volume (4730 cubic centimeters).",
    "Finally, we convert the total number of pennies to dollars: 21350 pennies / 100 = $213.50. Therefore, a rough estimation of the total value of the coins in the jar might be around $213.50."
  )
)
save_table(df_reasoning, "si_tab_ai_reasoning",
           caption = "AI's Step-by-Step Reasoning for Estimating the Value of Coins in a Jar")

message("\nDone. All artifacts written to: ", out_dir)

# =============================================================================
# ROBUSTNESS CHECKS
#
# These do NOT replace the manuscript results above. They re-run the key
# analyses under stricter / alternative assumptions so the headline claims can
# be assessed side-by-side. All output goes to output/robustness/.
#
# Reproducibility note: results are deterministic only when the script is run
# start-to-finish (the bootstrap/permutation draws depend on the RNG stream
# seeded once at the top with set.seed(4881)). We reseed locally below so the
# robustness block is reproducible on its own as well.
# =============================================================================
message("\n================  ROBUSTNESS CHECKS  ================")
set.seed(4881)

# Reload clean copies so the robustness block does not depend on in-place
# mutations made earlier in the script (e.g. the reversed `value` factor).
rb_tutorgpt      <- readRDS(file.path(data_dir, "tutorgpt.rds"))
rb_wide          <- readRDS(file.path(data_dir, "tutorgpt_wide.rds"))

# -----------------------------------------------------------------------------
# R1. Balance table: omnibus randomization check instead of 20 marginal tests
#     Suggestion: a single test that treatment is unpredictable from covariates
#     is cleaner than 20 Fisher tests and avoids the "1 in 20 significant"
#     multiple-comparisons artifact.
# -----------------------------------------------------------------------------
message("\n[R1] Omnibus randomization / balance checks")
balance_vars <- c("gender", "has_used_before", "location", "top_grades",
                  "hours_per_week", "on_time_completion", "factors_contributing",
                  "q5_self_physics", "q6_self_technology", "q7_self_swimming_pool")
balance_vars <- intersect(balance_vars, names(rb_tutorgpt))

omnibus_one <- function(treat) {
  d <- rb_tutorgpt %>%
    dplyr::select(dplyr::all_of(c(treat, balance_vars))) %>%
    stats::na.omit()
  d[[treat]] <- factor(d[[treat]])
  full  <- glm(reformulate(balance_vars, response = treat),
               data = d, family = binomial())
  null  <- glm(reformulate("1", response = treat),
               data = d, family = binomial())
  lrt   <- anova(null, full, test = "LRT")
  data.frame(
    randomization = treat,
    n             = nrow(d),
    df            = lrt$Df[2],
    lr_chisq      = lrt$Deviance[2],
    p_value       = lrt$`Pr(>Chi)`[2]
  )
}

omnibus_tbl <- dplyr::bind_rows(
  omnibus_one("treatment_tutor_id"),
  omnibus_one("treatment_explain_id")
)
save_table_to(
  omnibus_tbl, rob_dir, "R1_balance_omnibus_LRT",
  caption = paste0(
    "Omnibus balance check: likelihood-ratio test of H0 that no covariate ",
    "predicts treatment assignment (logistic regression of treatment on all ",
    "covariates vs intercept-only). Non-significant p supports randomization."
  )
)
# Also record the Bonferroni / BH-adjusted view of the original 20 Fisher tests.
fisher_p <- function(treat) {
  sapply(balance_vars, function(v) {
    tryCatch(fisher.test(table(rb_tutorgpt[[v]], rb_tutorgpt[[treat]]),
                         simulate.p.value = TRUE, B = 1e4)$p.value,
             error = function(e) NA_real_)
  })
}
fisher_tbl <- data.frame(
  variable        = balance_vars,
  p_socratic      = fisher_p("treatment_tutor_id"),
  p_explain       = fisher_p("treatment_explain_id")
)
all_p <- c(fisher_tbl$p_socratic, fisher_tbl$p_explain)
fisher_tbl$p_socratic_BH <- p.adjust(fisher_tbl$p_socratic,
                                     method = "BH", n = length(all_p))
fisher_tbl$p_explain_BH  <- p.adjust(fisher_tbl$p_explain,
                                     method = "BH", n = length(all_p))
save_table_to(
  fisher_tbl, rob_dir, "R1_balance_fisher_BH_adjusted",
  caption = "Marginal Fisher tests with Benjamini-Hochberg adjustment across all 20 tests."
)

# -----------------------------------------------------------------------------
# R2. Bootstrap accuracy (RQ1): the headline causal claim.
#     Suggestions implemented:
#       (a) report two-sided AND one-sided p consistently, with a matching CI;
#       (b) show the result WITH and WITHOUT the 6969 outlier;
#       (c) add a permutation test of the median difference (a proper test of
#           H0: no treatment effect) and a Hodges-Lehmann / Wilcoxon estimate.
# -----------------------------------------------------------------------------
message("\n[R2] RQ1 accuracy: outlier sensitivity + permutation test")
coins_value <- 379.54

make_err <- function(data) {
  data %>%
    dplyr::mutate(abs_err = abs(q12_guess_coins_final - coins_value)) %>%
    dplyr::select(treatment_explain_id, abs_err) %>%
    stats::na.omit()
}

boot_median_diff <- function(err, n_boot = 1999) {
  grps <- split(err$abs_err, err$treatment_explain_id)
  stopifnot(length(grps) == 2)
  reps <- replicate(n_boot, {
    median(sample(grps[[2]], replace = TRUE)) -
      median(sample(grps[[1]], replace = TRUE))
  })
  reps
}

perm_median_diff <- function(err, n_perm = 4999) {
  x <- err$abs_err
  g <- err$treatment_explain_id
  obs <- diff(tapply(x, g, median))           # group2 - group1
  perm <- replicate(n_perm, {
    gp <- sample(g)
    diff(tapply(x, gp, median))
  })
  # two-sided permutation p-value (add-one correction)
  p_two <- (sum(abs(perm) >= abs(obs)) + 1) / (n_perm + 1)
  p_one <- (sum(perm <= obs) + 1) / (n_perm + 1)  # H1: treatment lowers error
  list(obs = as.numeric(obs), p_two = p_two, p_one = p_one)
}

summarise_accuracy <- function(label, data) {
  err <- make_err(data)
  reps <- boot_median_diff(err)
  ci90 <- quantile(reps, c(0.05, 0.95))
  ci95 <- quantile(reps, c(0.025, 0.975))
  p_one <- mean(reps > 0)                 # bootstrap directional mass
  p_two <- 2 * min(mean(reps > 0), mean(reps < 0))
  perm <- perm_median_diff(err)
  wt <- suppressWarnings(
    wilcox.test(abs_err ~ treatment_explain_id, data = err, conf.int = TRUE)
  )
  data.frame(
    sample              = label,
    n                   = nrow(err),
    boot_median_diff    = median(reps),
    boot_90CI_low       = ci90[1], boot_90CI_high = ci90[2],
    boot_95CI_low       = ci95[1], boot_95CI_high = ci95[2],
    boot_p_one_sided    = p_one,
    boot_p_two_sided    = p_two,
    perm_obs_median_diff = perm$obs,
    perm_p_one_sided    = perm$p_one,
    perm_p_two_sided    = perm$p_two,
    HL_shift_estimate   = unname(wt$estimate),
    wilcox_p_two_sided  = wt$p.value,
    row.names = NULL
  )
}

accuracy_rob <- dplyr::bind_rows(
  summarise_accuracy("with_outlier (all N=122)", rb_tutorgpt),
  summarise_accuracy("manuscript (<6000, N=121)",
                     dplyr::filter(rb_tutorgpt, q12_guess_coins_final < 6e3))
)
save_table_to(
  accuracy_rob, rob_dir, "R2_accuracy_outlier_and_permutation",
  caption = paste0(
    "RQ1 median absolute-error difference (AI reasoning minus control). ",
    "Rows contrast including vs excluding the single 6969 outlier. ",
    "Bootstrap, permutation, and Wilcoxon/Hodges-Lehmann inference reported together. ",
    "Negative median difference = lower error (greater accuracy) under AI reasoning."
  )
)

# -----------------------------------------------------------------------------
# R3. Confidence & helpfulness: respect the repeated-measures structure.
#     Suggestion: the pooled clm()/polr() treat 3 rows/student as independent.
#     Refit with a cumulative-link MIXED model clmm() with a student random
#     intercept and a CONSISTENT specification across tasks.
# -----------------------------------------------------------------------------
message("\n[R3] Ordinal MIXED models (clmm) with student random effects")
rb_wide_m <- rb_wide %>%
  dplyr::mutate(
    treatment_tutor_id = factor(treatment_tutor_id, c("non_socratic", "socratic")),
    name = factor(name),
    student_id = factor(student_id)
  )

tidy_or <- function(fit, model_label) {
  s <- summary(fit)$coefficients
  keep <- grep("treatment_tutor_id", rownames(s))
  est <- s[keep, "Estimate"]
  se  <- s[keep, "Std. Error"]
  data.frame(
    model     = model_label,
    term      = rownames(s)[keep],
    estimate  = est,
    std.error = se,
    odds_ratio = exp(est),
    OR_low    = exp(est - 1.96 * se),
    OR_high   = exp(est + 1.96 * se),
    p_value   = s[keep, grep("Pr", colnames(s))[1]],
    row.names = NULL
  )
}

# Confidence (pooled, consistent controls, student random intercept)
cl_conf <- ordinal::clmm(
  value ~ treatment_tutor_id + name + conf_value + (1 | student_id),
  data = rb_wide_m
)
# Helpfulness (same structure)
cl_help <- ordinal::clmm(
  helpful ~ treatment_tutor_id + name + conf_value + (1 | student_id),
  data = rb_wide_m
)

clmm_tbl <- dplyr::bind_rows(
  tidy_or(cl_conf, "confidence (clmm, +student RE)"),
  tidy_or(cl_help, "helpfulness (clmm, +student RE)")
)
save_table_to(
  clmm_tbl, rob_dir, "R3_ordinal_mixed_clmm",
  caption = paste0(
    "Cumulative-link MIXED models (ordinal::clmm) with a student random ",
    "intercept and a consistent specification across tasks. Odds ratios for ",
    "the Socratic treatment on confidence and perceived helpfulness. ",
    "Note the higher factor level is the reference as stored in the data."
  )
)
save_text_to({
  cat("=== clmm: confidence ===\n"); print(summary(cl_conf))
  cat("\n\n=== clmm: helpfulness ===\n"); print(summary(cl_help))
}, rob_dir, "R3_ordinal_mixed_clmm_fullsummary")

# -----------------------------------------------------------------------------
# R4. Learning (RQ3): paired within-student pre/post test instead of two
#     independent cross-sectional LPMs.
#     Suggestions implemented: McNemar paired test on correctness before vs
#     after AI, plus a mixed logistic model with pre/post x treatment
#     interaction to test whether the AI effect differs by Socratic condition.
# -----------------------------------------------------------------------------
message("\n[R4] RQ3 learning: paired McNemar + mixed logistic pre/post x treatment")
learn <- rb_tutorgpt %>%
  dplyr::transmute(
    student_id = dplyr::row_number(),
    treatment_tutor_id = factor(treatment_tutor_id, c("non_socratic", "socratic")),
    before = q25_sound_speed == "water_faster_higher_density",
    after  = q26_sound_speed_with_ai == "water_faster_higher_density"
  ) %>%
  stats::na.omit()

# McNemar paired test (before vs after AI, within student)
mc <- stats::mcnemar.test(table(before = learn$before, after = learn$after))
save_text_to({
  cat("Paired correctness, within student (sound-speed item):\n")
  print(table(before = learn$before, after = learn$after))
  cat(sprintf("\nBefore AI correct: %.1f%%\n", 100 * mean(learn$before)))
  cat(sprintf("After  AI correct: %.1f%%\n", 100 * mean(learn$after)))
  cat("\nMcNemar's test (H0: no within-student change before vs after AI):\n")
  print(mc)
}, rob_dir, "R4_learning_mcnemar")

# Mixed logistic: does the pre->post gain differ by Socratic condition?
learn_long <- learn %>%
  tidyr::pivot_longer(c(before, after), names_to = "phase", values_to = "correct") %>%
  dplyr::mutate(phase = factor(phase, c("before", "after")),
                student_id = factor(student_id))

glmm_learn <- lme4::glmer(
  correct ~ phase * treatment_tutor_id + (1 | student_id),
  data = learn_long, family = binomial()
)
save_text_to({
  cat("Mixed logistic model: correct ~ phase * treatment + (1|student)\n")
  cat("Interaction phaseafter:treatment_tutor_idsocratic tests whether the ",
      "AI-driven accuracy gain differs between Socratic and non-Socratic.\n\n", sep = "")
  print(summary(glmm_learn))
}, rob_dir, "R4_learning_glmer_prepost_interaction")

glmm_learn_tbl <- broom.mixed::tidy(glmm_learn, effects = "fixed", conf.int = TRUE) %>%
  dplyr::mutate(odds_ratio = exp(estimate),
                OR_low = exp(conf.low), OR_high = exp(conf.high))
save_table_to(
  glmm_learn_tbl, rob_dir, "R4_learning_glmer_coefs",
  caption = "Fixed effects (log-odds and odds ratios) from the pre/post x treatment mixed logistic model."
)

# -----------------------------------------------------------------------------
# R5. Multiple-comparisons view of the borderline primary outcome tests.
#     Suggestion: collect the headline p-values and show BH-adjusted q-values
#     so fragile (p ~ .025-.05) findings are transparent.
# -----------------------------------------------------------------------------
message("\n[R5] Multiple-comparisons summary of primary outcome tests")

# Helpfulness Fisher (pooled)
p_help_fisher <- tryCatch(
  fisher.test(table(rb_wide$helpful, rb_wide$treatment_tutor_id),
              simulate.p.value = TRUE, B = 1e4)$p.value,
  error = function(e) NA_real_)

# Perceived human-accuracy ordinal regression (AI-reasoning effect)
rev_ord <- function(x) factor(x, rev(levels(x)), ordered = TRUE)
fit_human <- MASS::polr(
  rev_ord(q11_guess_coins_human_accuracy) ~ treatment_explain_id +
    location + has_used_before + gender, rb_tutorgpt)
ch <- coef(summary(fit_human))
row_h <- grep("treatment_explain_id", rownames(ch))
p_human_reg <- 2 * pnorm(abs(ch[row_h, "t value"]), lower.tail = FALSE)

# Bootstrap/permutation accuracy (manuscript sample) from R2
acc_row <- accuracy_rob[accuracy_rob$sample == "manuscript (<6000, N=121)", ]

primary <- data.frame(
  test = c(
    "RQ1 accuracy (permutation, two-sided)",
    "RQ1 accuracy (bootstrap, one-sided)",
    "RQ2 perceived human accuracy (ordinal reg.)",
    "RQ5 helpfulness (Fisher, pooled)"
  ),
  p_value = c(
    acc_row$perm_p_two_sided,
    acc_row$boot_p_one_sided,
    p_human_reg,
    p_help_fisher
  )
)
primary$q_value_BH <- p.adjust(primary$p_value, method = "BH")
primary$q_value_bonferroni <- p.adjust(primary$p_value, method = "bonferroni")
save_table_to(
  primary, rob_dir, "R5_primary_outcomes_multiplicity",
  caption = paste0(
    "Headline outcome p-values with Benjamini-Hochberg (FDR) and Bonferroni ",
    "adjustment. Shows how borderline findings (p ~ .025-.05) hold up under ",
    "correction for the number of primary tests."
  )
)

# =============================================================================
# RESULTS: LLM-rated student behaviour and Socratic conduct (rev/sixth)
#
# Follows docs/prespecification.md (written before the holdout chats were
# rated). Inputs, all produced by the separate pipeline in llm_annotation/:
# output/llm_ratings_holdout_long.csv (holdout ratings),
# output/reliability_holdout/reliability_table.csv, input/holdout_ids.json,
# output/llm_ratings_dev_v3_long.csv.
# Outputs: output/tables/tab_llm_*.{txt,csv}, output/figures/fig_llm_*.pdf
# Note: dplyr:: is explicit for select() because MASS masks it.
# =============================================================================
message("\n[Results] LLM-rated student behaviour and Socratic conduct")

suppressPackageStartupMessages({ library(lme4); library(jsonlite); library(readr) })

llm_dir <- file.path(root, "llm_annotation")
llm_holdout <- fromJSON(file.path(llm_dir, "input", "holdout_ids.json"))

# ---- Chat-level covariates ----------------------------------------------------
llm_chat_info <- chats %>%
  dplyr::filter(user_id != 1) %>%
  dplyr::group_by(chat_id) %>%
  dplyr::summarise(
    student = dplyr::first(user_id),
    arm     = dplyr::first(treatment_tutor_id),
    school  = dplyr::first(location),
    start   = min(created_at),
    n_msgs  = sum(role == "user"),
    n_words = sum(words[role == "user"], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::group_by(student) %>%
  dplyr::mutate(chat_order = rank(start, ties.method = "first")) %>%  # proxy for task
  dplyr::ungroup() %>%
  dplyr::mutate(
    arm = factor(arm, levels = c("non_socratic", "socratic")),
    log_msgs = log(n_msgs), log_words = log1p(n_words)
  )

llm_ratings <- read_csv(file.path(llm_dir, "output", "llm_ratings_holdout_long.csv"), show_col_types = FALSE) %>%
  dplyr::mutate(
    rubric = sub("^rate_", "", sub("__.*", "", rater)),
    mode   = ifelse(student_only, "student_only", "full")
  )
stopifnot(setequal(unique(llm_ratings$chat_id), llm_holdout))

# ---- Reliability gate (pre-specified: alpha >= .67; binary: >= 80% & AC1 >= .60)
llm_rel <- read_csv(file.path(llm_dir, "output", "reliability_holdout", "reliability_table.csv"),
                    show_col_types = FALSE) %>%
  dplyr::transmute(
    rubric = sub("^rate_", "", prompt), mode = ifelse(mode == "student", "student_only", mode),
    item = dimension, n = n_chats, alpha = alpha_between_models,
    spearman, pct_agree, ac1
  ) %>%
  dplyr::mutate(
    pass   = ifelse(!is.na(pct_agree), pct_agree >= 80 & ac1 >= 0.60, alpha >= 0.67),
    status = ifelse(pass, "primary", "exploratory")
  )
save_table(llm_rel, "tab_llm_reliability", digits = 2,
           caption = "Between-rater agreement on the holdout chats (pre-specified thresholds).")
llm_status <- llm_rel %>% dplyr::filter(mode == "full") %>% dplyr::select(rubric, item, status)

# ---- Outcomes: mean of the two raters' z-scores (question_asking: mean 0/1) ---
llm_items <- tibble::tibble(
  rubric = c(rep("student", 4), rep("socratic", 4)),
  item   = c("reasoning_quality", "knowledge_building", "effort_seriousness", "question_asking",
             "supportive_guidance", "next_step_guidance", "encouraging_tone", "conversational_flow"),
  family = c(rep("A: student behaviour", 4), rep("B: Socratic conduct", 4))
)

llm_long <- llm_ratings %>%
  dplyr::rename(item = dimension) %>%
  dplyr::semi_join(llm_items, by = c("rubric", "item")) %>%
  dplyr::group_by(rubric, mode, item, model) %>%
  dplyr::mutate(z = ifelse(item == "question_asking", score, as.numeric(scale(score)))) %>%
  dplyr::ungroup()

llm_outcome <- llm_long %>%
  dplyr::group_by(chat_id, rubric, mode, item) %>%
  dplyr::summarise(y = mean(z, na.rm = TRUE), .groups = "drop") %>%
  dplyr::left_join(llm_chat_info, by = "chat_id")

# ---- Descriptives -------------------------------------------------------------
llm_desc <- llm_outcome %>% dplyr::filter(mode == "full") %>%
  dplyr::group_by(rubric, item, arm) %>%
  dplyr::summarise(mean = mean(y), sd = sd(y), n = dplyr::n(), .groups = "drop")
save_table(llm_desc, "tab_llm_descriptives", digits = 2,
           caption = "Item scores by arm (holdout, full dialogue; z units, question_asking in proportion units).")

llm_volume <- llm_chat_info %>% dplyr::filter(chat_id %in% llm_holdout) %>%
  dplyr::group_by(arm) %>%
  dplyr::summarise(chats = dplyr::n(), students = dplyr::n_distinct(student),
                   median_student_msgs = median(n_msgs), median_student_words = median(n_words),
                   .groups = "drop")
save_table(llm_volume, "tab_llm_interaction_volume", digits = 1,
           caption = "Interaction volume by arm (holdout chats).")

p_llm_desc <- ggplot(dplyr::filter(llm_outcome, mode == "full"), aes(arm, y, fill = arm)) +
  geom_violin(alpha = .4, colour = NA) +
  stat_summary(fun = mean, geom = "point", size = 2.5) +
  facet_wrap(~item, scales = "free_y", nrow = 2) +
  scale_fill_manual(values = palette) + guides(fill = "none") +
  labs(x = NULL, y = "Item score (mean of two raters' z-scores)",
       title = "LLM ratings by arm (holdout, full dialogue)")
save_fig(p_llm_desc, "fig_llm_ratings_by_arm", width = 9, height = 5.5)

# ---- Primary models -----------------------------------------------------------
# score ~ arm + school + chat order [+ log messages + log words] + (1 | student)
llm_fit <- function(d, adjusted) {
  f <- if (adjusted) y ~ arm + school + chat_order + log_msgs + log_words + (1 | student)
       else y ~ arm + school + chat_order + (1 | student)
  m  <- lmer(f, d, REML = TRUE, control = lmerControl(optimizer = "bobyqa"))
  cf <- summary(m)$coefficients["armsocratic", ]
  ci <- suppressMessages(confint(m, "armsocratic", method = "Wald"))
  tibble::tibble(est = cf[["Estimate"]], se = cf[["Std. Error"]], p = cf[["Pr(>|t|)"]],
                 lo = ci[1], hi = ci[2], n = nobs(m), students = lme4::ngrps(m)[["student"]])
}
llm_run <- function(data, mode_sel = "full", label = "primary", specs = c("unadjusted", "adjusted")) {
  data %>% dplyr::filter(mode == mode_sel) %>%
    dplyr::group_by(rubric, item) %>%
    dplyr::group_modify(~ dplyr::bind_rows(lapply(specs, function(s)
      dplyr::mutate(llm_fit(.x, s == "adjusted"), spec = s)))) %>%
    dplyr::ungroup() %>% dplyr::mutate(analysis = label)
}

llm_res <- llm_run(dplyr::filter(llm_outcome, chat_id %in% llm_holdout)) %>%
  dplyr::left_join(llm_items, by = c("rubric", "item")) %>%
  dplyr::group_by(family, spec) %>% dplyr::mutate(p_bh = p.adjust(p, "BH")) %>% dplyr::ungroup() %>%
  dplyr::left_join(llm_status, by = c("rubric", "item")) %>%
  dplyr::arrange(family, item, spec)
save_table(dplyr::select(llm_res, family, item, status, spec, est, lo, hi, p, p_bh, n, students),
           "tab_llm_effects", digits = 3,
           caption = "Socratic minus non-Socratic, linear mixed models (holdout). BH within family.")

p_llm_forest <- ggplot(llm_res, aes(est, reorder(item, est), colour = spec, shape = status)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_pointrange(aes(xmin = lo, xmax = hi), position = position_dodge(.5)) +
  facet_grid(family ~ ., scales = "free_y", space = "free_y") +
  scale_colour_manual(values = c("navy", "orange")) +
  labs(x = "Socratic − non-Socratic (z units; 95% CI)", y = NULL, colour = NULL,
       shape = "Reliability", title = "Unadjusted vs adjusted for message and word counts")
save_fig(p_llm_forest, "fig_llm_effects", width = 8, height = 6)

# ---- Each rater separately (sensitivity 2) -------------------------------------
llm_per_rater <- llm_long %>% dplyr::filter(mode == "full", chat_id %in% llm_holdout) %>%
  dplyr::mutate(y = z) %>% dplyr::left_join(llm_chat_info, by = "chat_id") %>%
  dplyr::group_by(rubric, item, model) %>% dplyr::group_modify(~ llm_fit(.x, TRUE)) %>%
  dplyr::ungroup()
save_table(llm_per_rater, "tab_llm_per_rater", digits = 3,
           caption = "Adjusted model, one rater at a time.")

# ---- Sensitivity analyses 1, 4, 5 ------------------------------------------------
llm_adj <- function(d, label) llm_run(d, "full", label, "adjusted")
llm_s4 <- llm_adj(dplyr::filter(llm_outcome, chat_id %in% llm_holdout, n_msgs > 1), "excl. 1-message chats")
llm_s1 <- llm_run(dplyr::filter(llm_outcome, chat_id %in% llm_holdout, rubric == "student"),
                  "student_only", "student-only ratings", "adjusted")

llm_dev <- read_csv(file.path(llm_dir, "output", "llm_ratings_dev_v3_long.csv"), show_col_types = FALSE) %>%
  dplyr::filter(rep == 1, !student_only) %>%
  dplyr::mutate(rubric = sub("^rate_", "", sub("__.*", "", rater)), mode = "full") %>%
  dplyr::rename(item = dimension)
llm_pairs <- tibble::tibble(rubric = c("student", "student", "socratic", "socratic"),
                            model  = c("gpt-4o-mini", "claude-haiku-5-5", "claude-haiku-5-5", "gpt-4o"))
llm_same_prompt <- llm_ratings %>% dplyr::distinct(rubric, prompt_hash) %>%
  dplyr::inner_join(dplyr::distinct(llm_dev, rubric, prompt_hash), by = c("rubric", "prompt_hash"))
llm_dev <- llm_dev %>%
  dplyr::semi_join(llm_pairs, by = c("rubric", "model")) %>%
  dplyr::semi_join(llm_same_prompt, by = c("rubric", "prompt_hash")) %>%
  dplyr::semi_join(llm_items, by = c("rubric", "item"))
llm_all <- dplyr::bind_rows(
    dplyr::select(dplyr::filter(llm_long, mode == "full"), chat_id, rubric, mode, item, model, score),
    dplyr::select(llm_dev, chat_id, rubric, mode, item, model, score)) %>%
  dplyr::group_by(rubric, item, model) %>%
  dplyr::mutate(z = ifelse(item == "question_asking", score, as.numeric(scale(score)))) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(chat_id, rubric, mode, item) %>%
  dplyr::summarise(y = mean(z, na.rm = TRUE), .groups = "drop") %>%
  dplyr::left_join(llm_chat_info, by = "chat_id")
llm_s5 <- llm_adj(llm_all, "all chats (holdout + development)")

llm_sens <- dplyr::bind_rows(
    dplyr::mutate(dplyr::filter(llm_res, spec == "adjusted"), analysis = "primary (holdout)"),
    llm_s4, llm_s1, llm_s5) %>%
  dplyr::select(analysis, rubric, item, est, lo, hi, p, n)
save_table(llm_sens, "tab_llm_sensitivity", digits = 3,
           caption = "Adjusted effect across pre-specified sensitivity analyses (1, 4, 5).")
p_llm_sens <- ggplot(llm_sens, aes(est, analysis)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey50") +
  geom_pointrange(aes(xmin = lo, xmax = hi)) +
  facet_wrap(~item, scales = "free_x", nrow = 2) +
  labs(x = "Socratic − non-Socratic (95% CI)", y = NULL)
save_fig(p_llm_sens, "fig_llm_sensitivity", width = 11, height = 6)

# ---- Does the rating carry information beyond interaction volume? (sens. 6) ------
llm_r2m <- function(m) {
  vf <- var(as.vector(model.matrix(m) %*% fixef(m)))
  vf / (vf + sum(sapply(VarCorr(m), function(x) as.numeric(x))) + sigma(m)^2)
}
llm_len <- llm_outcome %>% dplyr::filter(mode == "full", chat_id %in% llm_holdout) %>%
  dplyr::group_by(rubric, item) %>%
  dplyr::group_modify(~ {
    m0 <- lmer(y ~ school + chat_order + log_msgs + log_words + (1 | student), .x, REML = FALSE)
    m1 <- update(m0, . ~ . + arm)
    tibble::tibble(R2_length_only = llm_r2m(m0), R2_length_plus_arm = llm_r2m(m1),
                   LRT_p_arm_given_length = anova(m0, m1)[["Pr(>Chisq)"]][2])
  }) %>% dplyr::ungroup()
save_table(llm_len, "tab_llm_length_r2", digits = 3,
           caption = "Marginal R2 of length covariates, and LRT for arm given length.")

message("  (sensitivity 3, truncation to first 3 student messages, needs re-rating; not run)")

message("\nRobustness checks complete. See: ", rob_dir)

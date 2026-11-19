# 09_sample_characteristics: student characteristics by treatment arm (manuscript "Sample Characteristics" table).
# One row per answer category: % of students in each arm, Fisher's exact test of association with
# assignment (one p-value per characteristic), and the total count. All students are used (the test account is excluded).
# Also writes output/figures/fig_attitudes_AI.pdf (attitudes towards AI; all students)
# Reads:  raw
# Writes: output/tables/summary_statistics.csv (the manuscript only formats it)

if (!exists("raw")) { source("R/helpers.R"); source("steps/00_data.R") }

# `raw` includes the test account (student_id == 1); the analysis sample excludes it
students <- raw %>% dplyr::filter(student_id > 1)

characteristics <- students %>%
  dplyr::select(
    treatment_tutor_id, treatment_explain_id,
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

# Percent of each arm giving each answer, plus Fisher's exact p for the whole characteristic.
# `arm_col` is the treatment column; `suffix` names the p-value column.
by_arm <- function(arm_col, p_name) {
  characteristics %>%
    dplyr::select(-dplyr::all_of(setdiff(c("treatment_tutor_id", "treatment_explain_id"), arm_col))) %>%
    tidyr::pivot_longer(-dplyr::all_of(arm_col)) %>%
    dplyr::rename(arm = dplyr::all_of(arm_col)) %>%
    dplyr::mutate(p = fisher.test(xtabs(~ value + arm))$p.value, .by = name) %>%
    dplyr::count(name, value, arm, p) %>%
    na.omit() %>%
    dplyr::mutate(percent = 100 * n / sum(n), .by = c(name, arm)) %>%
    tidyr::pivot_wider(names_from = arm, values_from = c(percent, n), values_fill = 0) %>%
    dplyr::rename(!!p_name := p)
}

table_socratic <- by_arm("treatment_tutor_id", "pval") %>%
  dplyr::mutate(totals = n_non_socratic + n_socratic)
table_explain <- by_arm("treatment_explain_id", "pval_explain")

summary_statistics <- table_socratic %>%
  dplyr::left_join(table_explain, by = c("name", "value")) %>%
  dplyr::select(name, value, percent_socratic, percent_non_socratic, pval,
                percent_explain_yes, percent_explain_no, pval_explain, totals)

save_table(summary_statistics, "summary_statistics")

# ---- Figure: attitudes towards AI (manuscript Figure "attitudes-AI") ------------------
# Share of all students agreeing/disagreeing with four statements. Percentages add 1 to each
# count and 5 to the total (one pseudo-observation per answer category) so empty cells show 0-1%.
agree_labels <- c(
  strongly_agree = "S-Agree", agree = "Agree", neutral = "Neutral",
  disagree = "Disagree", strongly_disagree = "S-Disagree"
)
agree_colours <- c("#ca0020", "#f4a582", "#d1e5f0", "#92c5de", "#0571b0")

attitudes <- students %>%
  dplyr::select(
    "Society will benefit from a future of AI?" = q1_ai_future,
    "AI is dangerous" = q2_ai_danger,
    "AI is often misused by students" = q4_ai_misuse,
    "AI will foster students' learning in the future" = q3_ai_learning
  ) %>%
  tidyr::pivot_longer(dplyr::everything()) %>%
  dplyr::count(name, value) %>%
  dplyr::mutate(percent = 100 * (n + 1) / (sum(n) + 5), .by = name)

fig_attitudes <- attitudes %>%
  ggplot2::ggplot(ggplot2::aes(
    x = percent,
    y = factor(value, levels = names(agree_labels)),
    label = paste0(round(percent), "%"),
    fill = factor(value, levels = names(agree_labels))
  )) +
  ggplot2::geom_col(width = 0.8, show.legend = FALSE) +
  ggplot2::geom_text(ggplot2::aes(hjust = ifelse(percent < 5, -0.5, 0.5)),
                     position = ggplot2::position_stack(vjust = 0.5)) +
  ggplot2::facet_wrap(~ stringr::str_wrap(name, 30), scales = "free") +
  ggplot2::scale_y_discrete(labels = agree_labels) +
  ggplot2::scale_fill_manual(values = rev(agree_colours)) +
  ggplot2::labs(
    x = NULL, y = NULL,
    caption = paste0("Source: Full sample (n = ", nrow(students), ")"),
    title = "Student Attitudes on AI in Education",
    subtitle = "% of students who agree or disagree with the statement:"
  ) +
  ggplot2::theme_classic(base_size = 12) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold"),
    plot.subtitle = ggplot2::element_text(face = "italic"),
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(face = "bold"),
    axis.line.x = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_blank(),
    panel.spacing = grid::unit(2, "lines")
  )
save_figure(fig_attitudes, "fig_attitudes_AI", width = 8, height = 6)

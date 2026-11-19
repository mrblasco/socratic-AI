# 01_balance: did randomisation produce comparable arms?
# Reads:  dd
# Writes: output/tables/balance_smd.csv, balance_joint_test.csv, output/figures/balance.pdf

if (!exists("dd")) {
  source("R/helpers.R")
  source("steps/00_data.R")
}

# Standardised mean difference (Socratic minus non-Socratic);
# |SMD| < 0.25 is the usual benchmark
smd_bin <- function(x, z) {
  p1 <- mean(x[z == 1])
  p0 <- mean(x[z == 0])
  (p1 - p0) / sqrt((p1 * (1 - p1) + p0 * (1 - p0)) / 2)
}
smd_num <- function(x, z) {
  (mean(x[z == 1]) - mean(x[z == 0])) /
    sqrt((var(x[z == 1]) + var(x[z == 0])) / 2)
}
has <- function(x) !is.na(x)

bal <- tribble(
  ~covariate, ~smd,
  "School: Seville", smd_bin(dd$sev, dd$z),
  "Self-efficacy Task 1 (1-4)", smd_num(dd$eff1, dd$z),
  "Self-efficacy Task 2 (1-4)", smd_num(dd$eff2, dd$z),
  "Self-efficacy Task 3 (1-4)", smd_num(dd$eff3, dd$z),
  "Correct before AI (Task 3)", smd_bin(dd$pre_correct, dd$z),
  "Gender: girl", smd_bin(as.integer(dd$gender[has(dd$gender)] == "Girl"), dd$z[has(dd$gender)]),
  "Top grades", smd_bin(as.integer(dd$top_grades[has(dd$top_grades)] == "Top grades"), dd$z[has(dd$top_grades)]),
  "Used ChatGPT before", smd_bin(as.integer(dd$used_ai_before == "Yes"), dd$z),
  "Explanation arm (other experiment)", smd_bin(as.integer(dd$explain == "Yes"), dd$z)
)
save_table(bal, "balance_smd")

fig <- ggplot(bal, aes(smd, reorder(covariate, abs(smd)))) +
  annotate("rect", xmin = -0.25, xmax = 0.25, ymin = -Inf, ymax = Inf, fill = "grey90") +
  geom_vline(xintercept = 0, colour = "grey50") +
  geom_point(size = 2.5, colour = COL["Socratic"]) +
  labs(
    x = "Standardised mean difference", y = NULL,
    title = "Covariate balance (grey band = |SMD| < 0.25)"
  )
save_figure(fig, "balance")

# Joint test: do the covariates together predict assignment? (LR test against the null model)
bd <- dd %>% filter(has(gender), has(top_grades))
lr <- anova(glm(z ~ 1, binomial, bd),
  glm(z ~ school + eff1 + eff2 + eff3 + pre_correct + gender + top_grades + used_ai_before + explain, binomial, bd),
  test = "LRT"
)
save_table(tibble(chi2 = lr$Deviance[2], df = lr$Df[2], p = lr$`Pr(>Chi)`[2], n = nrow(bd)), "balance_joint_test")

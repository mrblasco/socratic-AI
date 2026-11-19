# 05_inference_robustness: multiplicity, randomisation inference, robustness, power (primary outcomes).
# Reads:  dd, and output/tables/confidence_effects.csv + correctness_effects.csv (written by steps 02 and 03)
# Writes: output/tables/primary_holm.csv, primary_randomisation_inference.csv, primary_robustness.csv, primary_mde.csv

if (!exists("dd")) { source("R/helpers.R"); source("steps/00_data.R") }
for (f in c("confidence_effects", "correctness_effects")) {
  if (!file.exists(file.path("output/tables", paste0(f, ".csv")))) stop("Run steps 02 and 03 first (missing ", f, ".csv)")
}

# ---- Holm correction across the four primary outcomes ----------------------------
# Adjusted models: ordinal logit for confidence, linear probability model for correctness.
conf_p <- read_table("confidence_effects") %>% filter(model == "Ordinal logit, adjusted (OR)") %>% select(outcome, p)
corr_p <- read_table("correctness_effects") %>% filter(model == "Adjusted risk difference (LPM, HC2)") %>% select(outcome, p)
holm <- bind_rows(conf_p, corr_p) %>%
  left_join(PRIMARY %>% select(outcome = id, label), by = "outcome") %>%
  mutate(p_holm = p.adjust(p, "holm")) %>% rename(p_raw = p)
save_table(holm, "primary_holm")

# ---- Randomisation inference (permute the tutor assignment within school) --------
set.seed(20261106)
ri <- bind_rows(lapply(1:4, function(i) {
  o <- PRIMARY[i, ]
  tr(ri_pvalue(o$y, covs_for(o$task), task_data(dd, o$task))) %>% mutate(outcome = o$id, label = o$label, .before = 1)
}))
save_table(ri, "primary_randomisation_inference")

# ---- Robustness of the adjusted effect to the specification ---------------------
lin <- function(y, covs, data) {      # Lin (2013): covariates centred and interacted with treatment
  dc <- data %>% mutate(across(all_of(covs), ~ .x - mean(.x)))
  ci_hc2(lm(reformulate(c("z", covs, paste0("z:", covs)), y), dc))
}
robust <- bind_rows(lapply(1:4, function(i) {
  o <- PRIMARY[i, ]; dk <- task_data(dd, o$task); covs <- covs_for(o$task)
  extra <- c("gender", "top_grades", "used_ai_before", "explain")
  dk2 <- dk %>% filter(!is.na(gender), !is.na(top_grades))
  within <- setdiff(covs, "sev")
  bind_rows(
    tibble(spec = "Unadjusted",                    tr(ci_hc2(lm(reformulate("z", o$y), dk)))),
    tibble(spec = "Adjusted (primary)",            tr(ci_hc2(lm(fml(o$y, covs), dk)))),
    tibble(spec = "Adjusted + gender, grades, prior AI use, explain arm", tr(ci_hc2(lm(fml(o$y, c(covs, extra)), dk2)))),
    tibble(spec = "Lin (2013) interacted",         tr(lin(o$y, covs, dk))),
    tibble(spec = "Brussels only",                 tr(ci_hc2(lm(fml(o$y, within), filter(dk, sev == 0))))),
    tibble(spec = "Seville only",                  tr(ci_hc2(lm(fml(o$y, within), filter(dk, sev == 1)))))
  ) %>% mutate(outcome = o$id, label = o$label, .before = 1)
}))
save_table(robust, "primary_robustness")

# ---- Minimum detectable effect (80% power, alpha = 0.05, two-sided) ---------------
n_arm <- mean(c(sum(dd$z), sum(1 - dd$z)))
mde_conf <- bind_rows(lapply(1:3, function(i) {
  sdk <- sd(task_data(dd, PRIMARY$task[i])$conf)
  dlt <- power.t.test(n = n_arm, sd = sdk, power = .8, sig.level = .05)$delta
  tibble(outcome = PRIMARY$id[i], label = PRIMARY$label[i], mde = dlt, unit = "scale points", mde_sd = dlt / sdk)
}))
p_ctrl <- mean(dd$post_correct[dd$z == 0])
mde_k <- uniroot(function(delta) power.prop.test(n = n_arm, p1 = p_ctrl, p2 = p_ctrl + delta, sig.level = .05)$power - .8,
                 c(.01, 1 - p_ctrl - 1e-3))$root
save_table(bind_rows(mde_conf, tibble(outcome = "K3", label = PRIMARY$label[4], mde = 100 * mde_k, unit = "percentage points", mde_sd = NA_real_)),
           "primary_mde")

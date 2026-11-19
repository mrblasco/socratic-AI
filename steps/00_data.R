# 00_data: build the analysis data from the raw questionnaire file.
# Reads:  analysis/data/processed/tutorgpt.rds
# Creates: `raw` (as stored), `d` (all students), `dd` (analysis sample, one row per student)
# Writes:  output/tables/missing_values.csv, output/tables/sample_by_school_arm.csv

if (!exists("save_table")) source("R/helpers.R")

raw <- readRDS("analysis/data/processed/tutorgpt.rds")

CORRECT <- "water_faster_higher_density"          # right answer to the Task 3 question
eff_code <- function(x) 5L - as.integer(x)        # 1 = couldn't do it alone ... 4 = could do easily

# Checks that the recodes below rest on what we think they do
stopifnot(
  levels(raw$q5_self_physics)[1] == "Could do easily",
  levels(raw$q6_self_technology)[1] == "Could do easily",
  levels(raw$q7_self_swimming_pool)[1] == "Could do easily",
  all(na.omit(raw$q15_guess_water_confidence) %in% CONF_LEVELS),
  all(na.omit(raw$q21_social_media_conf) %in% CONF_LEVELS),
  all(na.omit(raw$q27_sound_speed_conf) %in% CONF_LEVELS),
  all(na.omit(c(raw$q18_social_media_impact, raw$q19_social_media_impact_with_ai)) %in% OPIN_LEVELS)
)

d <- raw %>%
  filter(student_id > 1) %>% # 1 = test user
  mutate(
    .keep = "none",
    id = student_id,
    arm = factor(treatment_tutor_id, c("non_socratic", "socratic"), c("Non-Socratic", "Socratic")),
    z = as.integer(arm == "Socratic"),                    # 1 = Socratic tutor
    school = factor(location),
    sev = as.integer(location == "Seville"),
    explain = factor(treatment_explain_id, c("explain_no", "explain_yes"), c("No", "Yes")),
    gender = factor(gender),
    top_grades = factor(top_grades),
    used_ai_before = factor(has_used_before),
    init = q9_guess_coins_initial,                # initial guess
    final = q12_guess_coins_final,                # final guess
    # baseline self-efficacy for each task (1-4)
    eff1 = eff_code(q7_self_swimming_pool), eff2 = eff_code(q6_self_technology), eff3 = eff_code(q5_self_physics),
    # confidence in the answer after the tutor (1-5)
    conf1 = as.integer(factor(q15_guess_water_confidence, CONF_LEVELS)),
    conf2 = as.integer(factor(q21_social_media_conf, CONF_LEVELS)),
    conf3 = as.integer(factor(q27_sound_speed_conf, CONF_LEVELS)),
    # Task 3 correctness before / after the tutor
    pre_correct = as.integer(q25_sound_speed == CORRECT),
    post_correct = as.integer(q26_sound_speed_with_ai == CORRECT),
    # helpfulness of the tutor (raw answers; school-specific scales, coded below)
    h1_raw = q16_guess_water_ai_helpful, h2_raw = q22_social_media_ai_helpful, h3_raw = q28_sound_speed_ai_helpful,
    # post-treatment usage and Task 2 opinion
    turns1 = q14_tutor_interactions, turns2 = q19_tutor_interactions, turns3 = q26_tutor_interactions,
    op_pre = as.integer(factor(q18_social_media_impact, OPIN_LEVELS)),
    op_post = as.integer(factor(q19_social_media_impact_with_ai, OPIN_LEVELS)),
    verify_raw = q29_sound_speed_verify
  ) %>%
  mutate(help1 = help_code(h1_raw, school), help2 = help_code(h2_raw, school), help3 = help_code(h3_raw, school))

stopifnot(!anyDuplicated(d$id))

# Analysis sample: complete case on the primary outcomes and the Task 3 baseline
dd <- d %>% filter(!is.na(conf1), !is.na(conf2), !is.na(conf3), !is.na(post_correct), !is.na(pre_correct))
message(sprintf("  %d students, %d in the analysis sample", nrow(d), nrow(dd)))

save_table(
  d %>%
    summarise(across(c(arm, school, eff1, eff2, eff3, conf1, conf2, conf3, pre_correct, post_correct), ~ sum(is.na(.x)))) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "n_missing"),
  "missing_values")
save_table(dd %>% count(school, arm), "sample_by_school_arm")

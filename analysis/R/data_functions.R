library(dplyr)

# Functions ----------------------------------------
update_confidence <- function(x) {
  labels <-  c(
    easily = "Could do easily",
    effort = "Could do with a bit of effort",
    struggle = "I would struggle on my own",
    impossible = "I couldn't do this on my own"
  )
  factor(x, levels = names(labels), labels = labels)
}

update_hours_per_week <- function(x) {
  dplyr::case_match(
    x,
    c("2-3 hours", "3-4 hours", "4 or more hours") ~ "2+ hours",
    "<1 hours" ~ "0-1 hours",
    .default = x
  )
}

update_accuracy <- function(x) {
  factor(x, levels = c("very_good", "good", "neutral", "poor", "very_poor"), ordered = TRUE)
}

update_on_time_completion <- function(x) {
  dplyr::case_match(
    x,
    "always" ~ "Always on time",
    "usually" ~ "Usually on time", 
    c("rarely", "sometimes") ~ "Sometimes or rarely on time"
  )
}

create_top_grades <- function(x) {
  dplyr::case_match(x, c("A", "B") ~ "Top grades", 
                    c("C", "D", "E") ~ "Average or lower grades")
}

process_tutorgpt <- function(data) {
  dplyr::mutate(
    data,
    student_id          = dplyr::row_number(),
    has_used_before     = ifelse(!used_before %in% c("no", "I never use it"), "Yes", "No"),
    gender              = dplyr::case_match(gender, "female" ~ "Girl", "male" ~ "Boy"),
    top_grades          = avg_grade %>% create_top_grades(),
    hours_per_week      = hours_per_week %>% update_hours_per_week(),
    on_time_completion  = on_time_completion %>% update_on_time_completion(),
    q11_guess_coins_human_accuracy = q11_guess_coins_human_accuracy %>% update_accuracy(),
    q10_guess_coins_ai_accuracy = q10_guess_coins_ai_accuracy %>% update_accuracy(),
    # Mutate group of variables
    dplyr::across(c(q5_self_physics, q6_self_technology, q7_self_swimming_pool), update_confidence)
  )
}

# Chats 
count_words <- function(x) sapply(strsplit(as.character(x), " "), length)

process_chats <- function(data) {
  dplyr::mutate(
    dplyr::filter(data, !is.na(role)),
    words = count_words(message), 
    role_label = ifelse(role == "system", "AI Tutor", "Student")
  )
}

process_tutorgpt_wide <- function(data) {
  # Flip to long the initial confidence
  self_conf_wide <- data %>% 
    dplyr::select(
      student_id, 
      task1_water = q7_self_swimming_pool, 
      task2_media = q6_self_technology, 
      task3_sound = q5_self_physics
    ) %>% 
    pivot_longer(-c(student_id)) %>% 
    dplyr::rename(conf_value = value)

  # Flip to long helpflul
  helpful_wide <- data %>% 
    dplyr::select(
      student_id, 
      task1_water = q16_guess_water_ai_helpful, 
      task2_media = q22_social_media_ai_helpful, 
      task3_sound = q28_sound_speed_ai_helpful
    ) %>% 
    pivot_longer(-c(student_id)) %>% 
    dplyr::rename(helpful0 = value) %>% 
    dplyr::mutate(
      helpful = dplyr::case_match(
          helpful0,
          "Somewhat helpful" ~ "Neutral",
          "Slightly helpful" ~ "Not helpful",
          "Somewhat helpful" ~ "Helpful",
          "Extremely helpful" ~ "Very helpful",
          .default = helpful0
        )
    )

  confidence_labels <- c(
    very_confident = "Very confident",
    confident = "Confident", 
    neutral = "Neutral", 
    not_very_confident = "Not very confident",
    not_confident_at_all = "Not confident at all"
  )

  helpful_levels <- c(
    "Not at all helpful" = "Not at all Helpful", 
    "Not helpful" = "Not Helpful", 
    Neutral = "Neutral", 
    Helpful = "Helpful", 
    "Very helpful" = "Very Helpful"
  )


  # Flip to long the after-task confidence, and mrge
  tutorgpt_wide <- data %>% 
    dplyr::select(
      student_id, 
      task1_water = q15_guess_water_confidence, 
      task2_media = q21_social_media_conf, 
      task3_sound = q27_sound_speed_conf
    ) %>% 
    pivot_longer(-c(student_id)) %>% 
    dplyr::mutate(
      value = factor(value, names(confidence_labels), 
                    confidence_labels, ordered = TRUE)
    ) %>% 
    dplyr::left_join(self_conf_wide) %>% 
    dplyr::left_join(helpful_wide) %>% 
    dplyr::mutate(
      helpful = factor(helpful, names(helpful_levels), ordered = TRUE)
    ) %>% 
    dplyr::left_join(
      dplyr::select(data, student_id, location, has_used_before, 
                    gender, top_grades, treatment_tutor_id)
    )

  return(tutorgpt_wide)
}


load_and_process_tutorgpt <- function(path) {
  process_tutorgpt(readRDS(path))
}

load_and_process_tutorgpt_wide <- function(path) {
  process_tutorgpt_wide(load_and_process_tutorgpt(path))
}

load_and_process_chats <- function(path) {
  process_chats(readRDS(path))
}



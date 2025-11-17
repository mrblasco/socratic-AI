# ---- setup , include = F
library(dplyr)
library(jsonlite)
library(knitr)
library(lme4)
library(stargazer)

opts_chunk$set(
    echo = TRUE,
    message = FALSE,
    warning = FALSE,
    error = TRUE
)

# ---- data  ----

tutorgpt <- readRDS("analysis/data/processed/tutorgpt.rds")
chats <- readRDS("analysis/data/processed/chats.rds")

data_path <- "analysis/data/dialogues.csv"
ds <- read.csv(data_path, header = FALSE, col.names = c(
    "chat_id", "coherence", "accuracy", "depth", "engagement",
    "clarity", "learning_outcome", "comments"
))

data_path <- "analysis/data/dialogues_socratic_eval.csv"
ds_socratic <- read.csv(data_path, header = FALSE, col.names = c(
    "chat_id", "coherence_2", "identifying_mistake", "acknowledging_mistake", "supportive_guidance",
    "next_step_guidance", "conversational_flow", "encouraging_tone", "comments_socratic"
))


chat_info <- chats %>% 
    filter(role == "user") %>% 
    rename(student_id = user_id) %>%
    distinct(chat_id, student_id, treatment_tutor_id, location)

# merge
ds <- left_join(ds, chat_info, by = "chat_id") %>% 
    left_join(ds_socratic, by = "chat_id") %>% 
    left_join(count(chats, chat_id, name = "interactions"), by = "chat_id") %>%
    filter(student_id != 1)

# ---- analysis

fit_coherence <- lmer(
    scale(coherence) ~ treatment_tutor_id + location +
        scale(log(interactions)) + (1 | student_id),
    data = ds
)

fit_engagement <- update(fit_coherence, scale(engagement) ~ .)
fit_clarity <- update(fit_coherence, scale(clarity) ~ .)
fit_depth <- update(fit_coherence, scale(depth) ~ .)
fit_learning_outcome <- update(fit_coherence, scale(learning_outcome) ~ .)

fit_mistake_id <- update(fit_coherence, scale(identifying_mistake) ~ .)
fit_mistake_ack <- update(fit_coherence, scale(acknowledging_mistake) ~ .)

fit_supportive_guidance <- update(fit_coherence, scale(supportive_guidance) ~ .)
fit_next_step <- update(fit_coherence, scale(next_step_guidance) ~ .)
fit_conversational_flow <- update(fit_coherence, scale(conversational_flow) ~ .)
fit_encouraging_tone <- update(fit_coherence, scale(encouraging_tone) ~ .)


models_socratic <- list(
    "Supportive guidance" = fit_supportive_guidance,
    "Next step" = fit_next_step,
    "Encouraging tone" = fit_encouraging_tone,
    "Conversational flow" = fit_conversational_flow,
    "Mistake identification" = fit_mistake_id,
    "Mistake acknowledge" = fit_mistake_ack,
    "Clarity" = fit_clarity,
    "Engagement" = fit_engagement,
    "Depth" = fit_depth
)

stargazer::stargazer(
    models_socratic,
    title = "Linear Mixed Model Results — Socratic Rubric",
    label = "tab:socratic_lmm",
    type = "latex",
    covariate.labels = c("Socratic Tutor", "Constant"),
    dep.var.labels = names(models_socratic),
    digits = 2,
    no.space = TRUE,
    omit.stat = c("f", "ser"),
    omit = c("interaction", "location"),
    omit.labels = c("Exchanges", "School")
)


models <- list(
    "Coeherence" = fit_coherence,
    "Clarity" = fit_clarity,
    "Engagement" = fit_engagement,
    "Depth" = fit_depth,
    "Learning" = fit_learning_outcome
)

stargazer::stargazer(
    models,
    title = "Linear Mixed Model Results — Socratic Rubric",
    label = "tab:socratic_lmm",
    type = "latex",
    dep.var.labels = names(models),
    covariate.labels = c("Socratic Tutor", "Seville", "Interactions"),
    type = "text",
    omit.stat = c("f", "ser"),
    digits = 2,
    no.space = TRUE,
    float = TRUE,
    float.env = "table",
    table.placement = "ht!"
)


# ----- hhtml, results = "asis"

stargazer::stargazer(
    models,
    type = "html",
    title = "Regression Results (linear mixed model)",
    dep.var.labels = names(models),
    omit.stat = c("f", "ser"),
    omit = c("interaction", "location"),
    omit.labels = c("intera", "location"),
    digits = 2,
)

stargazer::stargazer(
    models_socratic,
    type = "html",
    title = "Regression Results (linear mixed model)",
    dep.var.labels = names(models_socratic),
    covariate.labels = c("Socratic Tutor", "Constant"),
    omit.stat = c("f", "ser"),
    omit = c("interaction", "loca"),
    omit.labels = c("Exchanges", "Location"),
    digits = 2
)
# ---- setup , include = F
require(dplyr)
require(jsonlite)
require(knitr)

opts_chunk$set(error = TRUE)

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


chat_info <- filter(chats, role == "user") %>% 
    rename(student_id = user_id) %>%
    distinct(chat_id, student_id, treatment_tutor_id, location)



ds <- left_join(ds, chat_info, by = "chat_id") %>% 
    left_join(ds_socratic, by = "chat_id") %>% 
    left_join(count(chats, chat_id, name = "interactions"), by = "chat_id")

str(ds)

ds <- filter(ds, student_id != 1)

kable(head(select(ds, -comments)))
#kable(head(tutorgpt))

# ---- analysis
require(lme4)

fit_coherence <- lmer(coherence ~ treatment_tutor_id + location + interactions + (1|student_id), data = ds)
fit_engagement <- update(fit_coherence, engagement ~ .)
fit_clarity <- update(fit_coherence, clarity ~ .)
fit_depth <- update(fit_coherence, depth ~ .)
fit_learning_outcome<- update(fit_coherence, learning_outcome ~ .)

fit_mistake_id <- update(fit_coherence, identifying_mistake ~ .)
fit_mistake_ack <- update(fit_coherence, acknowledging_mistake ~ .)

fit_supportive_guidance <- update(fit_coherence, supportive_guidance ~ .)
fit_next_step <- update(fit_coherence, next_step_guidance ~ .)
fit_conversational_flow <- update(fit_coherence, conversational_flow ~ .)

fit_encouraging_tone <- update(fit_coherence, encouraging_tone ~ .)


models <- list(
    "Mistake Id." = fit_mistake_id,
    "Mistake Ack." = fit_mistake_ack,
    "Guidance" = fit_supportive_guidance,
    "Next Step" = fit_next_step,
    "Conversation" = fit_conversational_flow,
    "Encouraging" = fit_encouraging_tone
)

stargazer::stargazer(
    models,
    title = "Regression Results (linear mixed model)",
    dep.var.labels = names(models),
    covariate.labels = c("Socratic Tutor", "Seville", "Interactions"),
    type = "text",
    omit.stat = c("f", "ser"),
    digits = 2
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
    title = "Regression Results (linear mixed model)",
    dep.var.labels = names(models),
    covariate.labels = c("Socratic Tutor", "Seville", "Interactions"),
    type = "text",
    omit.stat = c("f", "ser"),
    digits = 2
)
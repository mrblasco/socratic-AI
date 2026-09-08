# ---- setup , include = F
library(dplyr)
library(ggplot2)
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

theme_set(theme_classic())

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

ds_cognitive_path <- here::here("data/cognitive_engagement.csv")
ds_cognitive <- readr::read_csv(ds_cognitive_path) %>%
    rename(chat_id = dialogue_id)


chat_info <- chats %>%
    filter(role == "user") %>%
    rename(student_id = user_id) %>%
    distinct(chat_id, student_id, treatment_tutor_id, location)

# merge
ds <- left_join(ds, chat_info, by = "chat_id") %>%
    left_join(ds_socratic, by = "chat_id") %>%
    left_join(count(chats, chat_id, name = "interactions"), by = "chat_id") %>%
    filter(student_id != 1)

# Merge cogntive
ds_cognitive <- left_join(ds_cognitive, chat_info, by = "chat_id") %>%
    left_join(ds_socratic, by = "chat_id") %>%
    left_join(count(chats, chat_id, name = "interactions"), by = "chat_id") %>%
    filter(student_id != 1)

# ---- analysis cognitive ----

ds_reg <- ds_cognitive %>%
    mutate(
        interactions = scale(interactions)[, 1],
        coherence = scale(coherence)[, 1],
        coherence_2 = scale(coherence_2)[, 1],
    )

depvars <- setdiff(
    colnames(ds_reg),
    c("chat_id", "treatment_tutor_id", "comments", "student_id", "location", "comments_socratic")
)

# corr plot
library(ggcorrplot)

cor_mat <- cor(
    dplyr::select(ds_reg, depvars),
    use = "pairwise.complete.obs"
)
dist_mat <- as.dist(1 - cor_mat)
hc <- hclust(dist_mat, method = "average")
plot(hc)

clusters <- cutree(hc, k = 4)
cluster_df <- data.frame(
    depvar = names(clusters),
    cluster = as.numeric(clusters)
)

library(psych)
fa_result <- fa(
    select(ds_reg, all_of(depvars)),
    nfactors = 4,
    rotate = "oblimin"
)
summary(fa_result)
print(fa_result$loadings)

# Create loadings
loadings <- as.data.frame(unclass(fa_results$loadings))
factor_assignment <- apply(
    abs(loadings),
    1,
    which.max
)
cluster_fa_df <- data.frame(
    depvar = names(factor_assignment),
    fa_cluster = as.numeric(factor_assignment)
) %>% 
mutate(
    fa_cluster_label = case_when(
        fa_cluster == 1 ~ "Cognitive quality",
        fa_cluster == 2 ~ "Communication quality",
        fa_cluster == 3 ~ "Engagement effort",
        TRUE ~ "Other"
    )
)

get_vars <- function(cluster) {
    names(factor_assignment[factor_assignment == cluster])
}

ds_reg <- mutate(
    ds_reg,
    cognitive_quality = rowMeans(pick(all_of(get_vars(1)))),
    communication_quality = rowMeans(pick(all_of(get_vars(2)))),
    engagement_effort = rowMeans(pick(all_of(get_vars(3))))
)

ys <- c("cognitive_quality", "communication_quality", "engagement_effort")
fits <- lapply(ys, function(v) {
    lm(reformulate("treatment_tutor_id", v), ds_reg)
}) %>% 
setNames(ys)

library(modelsummary)
modelsummary(
    fits,
    stars = TRUE,
    coef_rename = c(
        "treatment_tutor_idsocratic" = "Socratic Agent"
    ),
    estimate = "{estimate}{stars}",
    statistic = "({std.error})",
    gof_omit = "IC|Log|F|RMSE|Std.Errors",
)

# Correlations 
fig_cormat <- ggcorrplot::ggcorrplot(
    cor_mat,
    type = "full",
    hc.order = TRUE, hc.rect = 3,
    colors = c("#6D9EC1", "white", "#E46726")
)

library(lme4)
library(broom.mixed)

results <- list()
for (j in seq_along(depvars)) {
    model <- reformulate(
        c("treatment_tutor_id", "(1|student_id)"),
        depvars[j]
    )
    fit <- lme4::lmer(
        model,
        data = ds_reg
    )
    results[[j]] <- fit
}

coeffs <- lapply(results, broom::tidy, conf.int = TRUE)
names(coeffs) <- depvars

plot_data <- bind_rows(coeffs, .id = "depvar") %>%
    filter(grepl("treat", term)) %>%
    left_join(cluster_df, by = "depvar") %>%
    left_join(cluster_fa_df, by = "depvar") %>% 
    mutate(depvar = reorder(depvar, estimate))

fig_coeffs <- plot_data %>%
    ggplot(aes(estimate, depvar, xmin = conf.low, xmax = conf.high)) +
    geom_vline(xintercept = 0) +
    geom_pointrange() +
    facet_wrap(
        ~fa_cluster_label,
        ncol = 1,
        scales = "free_y",
        space = "free_y"
    )


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

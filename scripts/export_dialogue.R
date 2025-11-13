# ---- setup, include=FALSE ----
library(knitr)
library(dplyr)
library(jsonlite)
opts_chunk$set(error = TRUE)

# ---- data
data_path <- file.path("analysis", "data", "processed")
data_files <- list.files(data_path, pattern = "*.rds", full.names = TRUE)

data_files
data <- lapply(data_files, readRDS)
chats <- filter(data[[1]], user_id != 1)

kable(head(chats), caption = "top rows")

# --- conversion

dialogues_json <- chats %>%
    group_by(chat_id) %>%
    arrange(created_at) %>%
    summarise(
        context = list(
            data.frame(
                speaker = role,
                utterance = message,
                stringsAsFactors = FALSE
            )
        )
    ) %>% 
    rename(
        dialogue_id = chat_id
    ) %>%
    select(dialogue_id, context)

json_output <- toJSON(dialogues_json, pretty = TRUE, auto_unbox = TRUE)

out_path <- file.path("analysis", "data", "dialogues.json")
writeLines(json_output, out_path)

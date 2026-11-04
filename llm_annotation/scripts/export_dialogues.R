# Export the chat logs to input/dialogues.json, the only input of the rating
# pipeline. Source: socraticaidata::chats (unique user_id / chat_id across
# schools). Run from llm_annotation/:
#   Rscript scripts/export_dialogues.R
#
# The package IDs are random (anonymised) and must not be linked back to the
# original IDs. The v1 export used analysis/data/processed/chats.rds, where
# user_id and chat_id restart in each school; grouping by chat_id merged 12
# Brussels and Seville chats (see README).
library(dplyr)
library(jsonlite)

data("chats", package = "socraticaidata")

# Researcher test account (Seville; "What tutor are u?", "What is 2 + 2?").
TEST_USER <- 120L
test <- distinct(filter(chats, user_id == TEST_USER), chat_id, location)
stopifnot(nrow(test) == 4, all(test$location == "Seville"))

dialogues <- chats %>%
    filter(user_id != TEST_USER) %>%
    arrange(chat_id, turn) %>%
    group_by(chat_id) %>%
    summarise(
        context = list(data.frame(
            speaker = role,
            utterance = message,
            stringsAsFactors = FALSE
        )),
        .groups = "drop"
    ) %>%
    rename(dialogue_id = chat_id)

stopifnot(nrow(dialogues) == 366)

out_path <- file.path("input", "dialogues.json")
writeLines(toJSON(dialogues, pretty = TRUE, auto_unbox = TRUE), out_path)
message("Wrote ", nrow(dialogues), " dialogues to ", out_path)

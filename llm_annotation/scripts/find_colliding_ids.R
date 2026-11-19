# Find chat IDs that are not unique across schools in analysis/data/processed/chats.rds.
# There, user_id and chat_id restart at 1 in each school. The v1 rating input (dialogues_v1.json)
# was keyed by chat_id alone, so each colliding ID merged a Brussels and a Seville chat and its
# ratings are invalid (see README, "Chat IDs"). Writes input/colliding_chat_ids.json.
# Run from llm_annotation/:  Rscript scripts/find_colliding_ids.R
library(dplyr)
library(jsonlite)

chats <- readRDS("../analysis/data/processed/chats.rds") %>%
    filter(!(location == "Seville" & user_id == 1))          # researcher test account
ids <- chats %>% distinct(location, chat_id) %>% count(chat_id) %>% filter(n > 1) %>% pull(chat_id)
stopifnot(length(ids) == 12)
holdout <- fromJSON("input/holdout_ids.json")
dev <- fromJSON("input/dev_subset_ids.json")
message("Colliding IDs: ", paste(sort(ids), collapse = " "))
message("In holdout: ", sum(ids %in% holdout), "; in development set: ", sum(ids %in% dev))
writeLines(toJSON(sort(ids)), "input/colliding_chat_ids.json")

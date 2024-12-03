

# Count number of words
count_words <- function(x) {
  words <- strsplit(as.character(x), " ")
  sapply(words, length)
}

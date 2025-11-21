center <- function(x) scale(x, center = TRUE, scale = FALSE)
topcode <- function(x, value) ifelse(x > value, value, x)

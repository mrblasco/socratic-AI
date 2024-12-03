
wrap_text <- function(x, w = 30) {
  gsub("\n", "<br>", stringr::str_wrap(x, width = w))
}

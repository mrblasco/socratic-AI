library(rmarkdown)

render_if_modified <- function(input,
                               timestamp_file = paste0(input, ".timestamp"),
                               ...) {

  input_mtime <- file.info(input)$mtime

  if (file.exists(timestamp_file)) {
    last_render_time <- as.POSIXct(readLines(timestamp_file, warn = FALSE))
  } else {
    last_render_time <- as.POSIXct(NA)
  }

  if (is.na(last_render_time) || input_mtime > last_render_time) {
    message("Re-rendering: file has changed.")
    out <- render(input, ...)
    writeLines(as.character(Sys.time()), timestamp_file)
    system(paste("open", out))
  } else {
    message("No changes detected.")
  }
}



watch_rmarkdown <- function(input,
                            interval = 2,   # seconds between checks
                            ...) {

  message("Watching for changes... Press Ctrl+C to stop.")

  repeat {
    render_if_modified(input, ...)
    Sys.sleep(interval)
  }
}

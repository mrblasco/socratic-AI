

save_plot_here <- function(filename, plot = ggplot2::last_plot(),
                      dirname = here::here("_figures"),
                      ...) {

  png_dir <- file.path(dirname, "png")
  pdf_dir <- file.path(dirname, "pdf")

  # Create directories if they do not exist
  if (!dir.exists(pdf_dir)) dir.create(pdf_dir, recursive = TRUE)
  if (!dir.exists(png_dir)) dir.create(png_dir, recursive = TRUE)

  # Define file paths
  png_path <- file.path(png_dir, paste0(filename, ".png"))
  pdf_path <- file.path(pdf_dir, paste0(filename, ".pdf"))

  # Save in PNG format
  ggplot2::ggsave(filename = png_path, plot = plot, ...)

  # Save in PDF format
  ggplot2::ggsave(filename = pdf_path, plot = plot, ...)

  # Print a success message
  message(paste("Plot saved successfully as PNG:", png_path))
  message(paste("Plot saved successfully as PDF:", pdf_path))

  if (interactive()) {
    system(sprintf("open '%s'", pdf_path))
  }

  return(png_path)
}

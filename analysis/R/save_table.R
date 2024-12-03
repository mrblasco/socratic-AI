
options(
  knitr.table.toprule = "\\toprule",
  knitr.table.midrule = "\\midrule\\arrayrulecolor{gray!20}",
  knitr.table.bottomrule = "\\arrayrulecolor{black}\\bottomrule"
)


# Script to write kable in latex
write_kable_latex <- function(x, file, keep_tex = TRUE) {
  stopifnot("kableExtra not found" = require(kableExtra, quietly = TRUE))
  
  origin <- getwd()
  on.exit(setwd(origin))
  
  temp_tex <- c("\\documentclass[border=1mm]{standalone}", 
      "\\usepackage{amssymb, amsmath}", kableExtra:::latex_pkg_list(), "\\usepackage{graphicx}", 
      "\\usepackage{xunicode}", "\\usepackage{xcolor}", 
      "\\begin{document}", kableExtra:::solve_enc(x), "\\end{document}")
  temp_tex <- paste(temp_tex, collapse = "\n")
  temp_tex_file <- tempfile(fileext = ".tex")
  writeLines(temp_tex, temp_tex_file, useBytes = TRUE)
  
  out <- tinytex::xelatex(temp_tex_file, pdf_file = file)
  if (keep_tex) {
    file.copy(temp_tex_file, gsub(".pdf$", ".tex", file))
  }
  invisible(out)
}


save_table <- function(x, file) {
  dir.create(here::here("tables"), showWarnings = FALSE)
  path <- here::here("tables", file)
  message("Saved tables on ", path)
  write(x, path)
}

tabulate_var <- function(formula, data, margin = 2, ...) {
  xt <- xtabs(formula, data, ...)
  xt_all <- addmargins(xt, 2, FUN = list(All = sum))
  percent <- prop.table(xt_all, 2) * 100
  rownames(percent) <- paste("%", rownames(percent))
  colnames(percent) <- sprintf('%s\n(n = %s)', colnames(xt_all), colSums(xt_all))
  return(percent)
}

tabulate_var_legacy <- function(formula, data, margin = 2, ...) {
  xt <- xtabs(formula, data, ...)
  percent <- prop.table(xt, margin) * 100
  xt <- addmargins(xt, 2, FUN = list(Total = sum))
  cbind(percent, xt)
}



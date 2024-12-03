require(dplyr, warn.conflicts = FALSE)

# Format standard errors 
format_se <- function(x, format = "%2.1f") {
  ifelse(is.na(x), "", paste0("(", sprintf(format, x), ")"))
}

# Functions format std.errors and estimates
format_est <- function(x, pval = NULL, format = "%2.1f") {
  stars <- dplyr::case_when(
    (0.05 < pval & pval < 0.1) ~ "*",
    (0.01 < pval & pval < 0.05) ~ "**",
    pval < 0.01 ~ "***",
    .default = ""
  )
  paste0(sprintf(format, x), stars)
}


# Functions extractin coefficients
extract_model_coefficients <- function(models, conf.int = TRUE) {
  bind_rows(
    lapply(models, function(model) {
      if (inherits(model, "merMod")) {
        broom::tidy(model, conf.int = conf.int, "fixed")
      } else {
        broom::tidy(model, conf.int = conf.int)
      }
    }),
    .id = "model"
  )
}

# Building table
build_model_table <- function(models, keep = NULL, stars = TRUE, format = "%2.2f") {
  if (!is.list(models) || any(!sapply(models, inherits, c("lm", "merMod")))) {
    stop("Input must be a list of model objects (e.g., lm).")
  }

  coeffs <- extract_model_coefficients(models)
  coeffs <- coeffs %>% 
    dplyr::mutate(
      estimate = if (stars) format_est(estimate, p.value, format) else format_est(estimate, NULL, format),
      std.error = format_se(std.error, format)
    )

  # Omit variables 
  if (!is.null(keep)) {
    coeffs <- dplyr::filter(coeffs, grepl(keep, term))
  }

  coeffs_wide <- coeffs %>% 
    dplyr::select(model, term, estimate, std.error) |>
    tidyr::pivot_longer(-c(model, term), names_to = "statistic") %>%
    tidyr::pivot_wider(names_from = model, values_from = value, values_fill = "") %>% 
    dplyr::mutate(term = ifelse(statistic == "estimate", term, ""))

  # Statistics
  stats <- dplyr::bind_rows(lapply(models, broom::glance), .id = "model")
  stats_wide <- data.frame(model = stats$model,  value = format(stats$nobs, big.mark = ","),
                         term = "N", statistic = "obs") %>% 
                tidyr::pivot_wider(values_from = value, names_from = model)

  return(dplyr::bind_rows(coeffs_wide, stats_wide))
}


save_kable_here <- function(x, ...) {
  current_dir <- getwd()
  on.exit(setwd(current_dir))
  kableExtra:::save_kable(x, ...)
}

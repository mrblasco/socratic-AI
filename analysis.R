#!/usr/bin/env Rscript
# =============================================================================
# analysis.R: runs the questionnaire analysis (Socratic vs non-Socratic AI tutor)
# and saves all tables and figures to output/.
#
# Usage (from the project root):
#   Rscript analysis.R
#
# Steps run in order and share one data frame, `dd`, built by steps/00_data.R.
# Each step lists what it reads and writes in its header. Shared functions are
# in R/helpers.R; only save_table() and save_figure() write files.
#
# A single step can be run on its own (it builds `dd` itself if needed), but
# steps 05 and 06 read tables written by steps 02 and 03.
# =============================================================================

source("R/helpers.R")
set.seed(20261106)

steps <- list.files("steps", full.names = TRUE)

for (s in steps) {
  message("Running ", s)
  source(s)
}

dir.create("output", showWarnings = FALSE)
writeLines(capture.output(sessionInfo()), "output/session_info.txt")
message("Done.")

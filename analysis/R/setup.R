# Define the list of packages you want
packages <- c("dplyr", "ggplot2", "tidyr", "readr", "kableExtra", "ggdist", "ggtext", "ggrepel", 
              "lme4", "broom.mixed", "patchwork", "lmerTest")

# Specify the CRAN repository
repo <- "https://cloud.r-project.org"  # This is a widely used CRAN mirror

# Identify packages that are not installed
packages_to_install <- packages[!(packages %in% installed.packages()[,"Package"])]

# Install missing packages without prompting for a CRAN mirror
if(length(packages_to_install) > 0) {
  install.packages(packages_to_install, repos = repo)
}

# Load all packages
lapply(packages, require, character.only = TRUE, quietly = TRUE)

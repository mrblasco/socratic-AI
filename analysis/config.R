library(dplyr)
library(tidyr)
library(ggplot2)
library(ggtext)
library(ggdist)

# Directories --------------------------------------------------
outpath <- here::here("figures_and_tables/v01/")
if (!dir.exists(outpath)) dir.create(outpath)


# Kable ... 
options(
  knitr.table.toprule = "\\toprule",
  knitr.table.midrule = "\\midrule\\arrayrulecolor{gray!20}",
  knitr.table.bottomrule = "\\arrayrulecolor{black}\\bottomrule"
)


# Theme for plots --------------------------------------------------
theme_set(theme_classic())

theme_update(
  plot.title = element_markdown(face = "bold", lineheight = 1.3),
  plot.subtitle = element_markdown(face = "italic", lineheight = 1.3),
  strip.background = element_blank(),
  strip.text = element_markdown(size = 11, lineheight = 1.2, face = "bold"),
)
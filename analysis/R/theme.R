library(ggplot2)
library(ggdist)
library(ggrepel)
library(ggtext)


# Theme
theme_set(theme_classic())

theme_update(
  plot.title = ggtext::element_markdown(face = "bold", lineheight = 1.3),
  plot.subtitle = ggtext::element_markdown(face = "italic", lineheight = 1.3),
  strip.background = element_blank(),
  strip.text = ggtext::element_markdown(size = 11, lineheight = 1.2, face = "bold"),
)

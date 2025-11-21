

theme_custom <- function() {
    ggplot2::theme_classic() +
        ggplot2::theme(
            plot.title = ggtext::element_markdown(face = "bold", lineheight = 1.3),
            plot.subtitle = ggtext::element_markdown(face = "italic", lineheight = 1.3),
            strip.background = ggplot2::element_blank(),
            strip.text = ggtext::element_markdown(size = 11, lineheight = 1.2, face = "bold")
        )
}

geom_coef <- function() {
    list(
        ggplot2::scale_color_manual(values = c("navy", "orange")),
        ggplot2::geom_vline(xintercept = 0, linetype = "dashed"),
        ggplot2::geom_linerange(linewidth = 3, alpha = 0.2),
        ggplot2::geom_point(size = 3),
        ggplot2::guides(colour = ggplot2::guide_legend(position = "inside"))
    )
}
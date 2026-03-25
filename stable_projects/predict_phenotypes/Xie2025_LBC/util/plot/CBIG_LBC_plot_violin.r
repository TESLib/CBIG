# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

CBIG_LBC_plot_violin <- function(df_m, outfile, model_order, fill_colors) {
# CBIG_LBC_plot_violin
#
# Generate a violin plot with overlaid boxplot for comparing correlations
# across multiple models and save to a PDF file.
#
# INPUTS:
#   df_m         - Data frame with columns:
#                    * model       : character or factor column of model labels
#                    * correlation : numeric column of prediction correlations
#   outfile      - Output PDF file path (e.g., '/path/to/violin.pdf')
#   model_order  - Character vector specifying the display order of models
#                  (e.g., c('FC_Y0', 'FC_Delta', 'FC_Y2'))
#   fill_colors  - Named or unnamed character vector of hex colors, one per model.
#                  If unnamed, colors are assigned in the order of model_order.
#
# OUTPUT:
#   PDF file saved to outfile (4 cm x 3.8 cm).
#
# EXAMPLE:
#   df_m <- data.frame(
#     model       = rep(c('FC_Y0', 'FC_Delta'), each = 100),
#     correlation = c(rnorm(100, 0.3), rnorm(100, 0.2))
#   )
#   CBIG_LBC_plot_violin(df_m, '/path/violin.pdf',
#     model_order  = c('FC_Y0', 'FC_Delta'),
#     fill_colors  = c('#4393C3', '#D6604D'))

  library(ggplot2)
  library(dplyr)

  stopifnot(length(fill_colors) == length(model_order))

  if (is.null(names(fill_colors))) {
    names(fill_colors) <- model_order
  }

  df_m <- df_m %>%
    mutate(
      model = trimws(as.character(model)),
      model = factor(model, levels = model_order)
    )

  p <- ggplot(df_m, aes(x = model, y = correlation, fill = model)) +
    geom_violin(trim = FALSE, color = "black", linewidth = 0.5, na.rm = TRUE) +
    geom_boxplot(width = 0.10, outlier.shape = NA, color = "black",
                 linewidth = 0.3, na.rm = TRUE) +
    scale_x_discrete(drop = FALSE) +
    scale_fill_manual(values = fill_colors, drop = FALSE) +
    scale_y_continuous(
      breaks = c(-0.2, 0, 0.2, 0.4, 0.6),
      labels = NULL
    ) +
    coord_cartesian(ylim = c(-0.2, 0.6)) +
    theme_minimal(base_size = 10) +
    theme(
      legend.position = "none",
      axis.title      = element_blank(),
      axis.text       = element_blank(),
      axis.ticks      = element_line(linewidth = 0.4),
      axis.line       = element_line(linewidth = 0.4),
      panel.grid      = element_blank(),
      plot.margin     = margin(1, 1, 1, 1, unit = "mm")
    )

  ggsave(outfile, plot = p, device = "pdf",
         width = 4, height = 3.8, units = "cm", useDingbats = FALSE)
}

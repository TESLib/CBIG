# Written by Yapei Xie and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
CBIG_LBC_chord_diagram_Yan_Kong17 <- function(input_path, min_thre, max_thre, width_cm, height_cm, outname) {
  
  if (!require(circlize)) install.packages('circlize')
  if (!require(igraph)) install.packages('igraph')
  if (!require(ComplexHeatmap)) {
    if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
    BiocManager::install("ComplexHeatmap")
  }
  if (!require(gridExtra)) install.packages('gridExtra')
  
  library(circlize)
  library(igraph)
  library(ComplexHeatmap)
  library(gridExtra)
  
  link_colorscale <- "bwr"
  
  data <- read.csv(input_path, header = FALSE)
  networks <- as.character(1:18)
  colnames(data) <- networks
  rownames(data) <- networks
  d <- data.matrix(data)
  g <- graph.adjacency(d, mode = "undirected", weighted = TRUE)
  df <- get.data.frame(g)
  
  outer_labels <- c("Default", "Control", "Lang", "Sal/Vent", "DorsAttn", "Aud", "SomMot", "Visual", "Subcort")
  outer_color <- rep('#000000', 9)
  outer_textcol <- '#000000'
  outer_fontsize <- 3
  inner_labels <- c('C','B','A','C','B','A','','B','A','B','A','','B','A','C','B','A','')
  inner_color <- c("#000082", "#CD3E4E", "#FFFF00", "#778CB0", "#87324A", "#E69422",
                   "#0C30FF", "#FF98D5", "#C43AFA", "#00760E", "#4A9B3C", "#DCF8A4",
                   "#2ACCA4", "#4682B4", "#7A8732", "#FF0000", "#781286", "#BF9959")
  inner_textcol <- rep('#000000', 18)
  inner_textcol[c(1, 5, 17)] <- '#FFFFFF'
  inner_fontsize <- 2
  gap_vec <- c(1, 1, 5, 1, 1, 5, 5, 1, 5, 1, 5, 5, 1, 5, 1, 1, 5, 5)
  
  circos.clear()
  pdf(paste0(outname, '.pdf'), width = width_cm / 2.54, height = height_cm / 2.54, useDingbats = FALSE)
  
  circos.par("start.degree" = 90, "gap.after" = gap_vec, unit.circle.segments = 10000, canvas.ylim = c(-1.1, 1.1))
  f <- factor(networks, levels = networks)
  circos.initialize(factors = f, xlim = c(0, 1))
  
  circos.track(factors = f, ylim = c(0, 1), track.height = 0.02, track.margin = c(0.01, 0), 
               bg.border = 'white', cell.padding = c(0, 1, 0, 1))
  
  highlight.sector(c('1', '2', '3'), track.index = 1, col = outer_color[1], text = outer_labels[1], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('4', '5', '6'), track.index = 1, col = outer_color[2], text = outer_labels[2], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('7'), track.index = 1, col = outer_color[3], text = outer_labels[3], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('8', '9'), track.index = 1, col = outer_color[4], text = outer_labels[4], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('10', '11'), track.index = 1, col = outer_color[5], text = outer_labels[5], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('12'), track.index = 1, col = outer_color[6], text = outer_labels[6], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('13', '14'), track.index = 1, col = outer_color[7], text = outer_labels[7], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('15', '16', '17'), track.index = 1, col = outer_color[8], text = outer_labels[8], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  highlight.sector(c('18'), track.index = 1, col = outer_color[9], text = outer_labels[9], 
                   text.col = outer_textcol, text.vjust = "7mm",
                   font = 1, cex = outer_fontsize, facing = "bending", niceFacing = TRUE)
  
  circos.track(factors = f, ylim = c(0, 1), track.height = 0.1, bg.col = inner_color, bg.lwd = rep(2, 18))
  circos.trackText(f, rep(0.5, 18), rep(0.5, 18), inner_labels, track.index = 2, facing = "bending", 
                   niceFacing = TRUE, font = 2, cex = inner_fontsize, col = inner_textcol)
  
  df <- df[abs(df$weight) >= min_thre, ]
  df$weight <- pmin(pmax(df$weight, -max_thre + 1e-10), max_thre)
  resolution <- 80
  breaks <- seq(-max_thre, max_thre, length.out = resolution + 1)
  df$color_level <- cut(df$weight, breaks = breaks, include.lowest = TRUE, labels = FALSE)
  
  if (link_colorscale == 'bwr') {
    bwr <- colorRamp2(c(-1, 0, 1), c("blue", "white", "red"), space = 'RGB')
    link_colors <- bwr(seq(-1, 1, length.out = resolution))
  }
  
  len <- max(table(c(df$from, df$to))) + 1.1
  link_breaks <- seq(0, 1, length.out = len)
  count <- rep(1, 18)
  for (row in 1:nrow(df)) {
    from <- df[row, "from"]
    to <- df[row, "to"]
    color_level <- df[row, "color_level"]
    from_num <- as.numeric(from)
    to_num <- as.numeric(to)
    
    if (from == to) {
      circos.link(from, link_breaks[1:2], to, link_breaks[(len - 1):len], col = link_colors[color_level])
    } else {
      count[from_num] <- count[from_num] + 1
      count[to_num] <- count[to_num] + 1
      circos.link(from, link_breaks[count[from_num]:(count[from_num] + 1)],
                  to, link_breaks[count[to_num]:(count[to_num] + 1)],
                  col = link_colors[color_level])
    }
  }
  
  dev.off()
}

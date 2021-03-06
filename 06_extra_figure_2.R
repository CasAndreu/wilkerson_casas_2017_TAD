#==============================================================================
# 06_extra_figure_2.R
# Purpose: extra Figure showing three Spectral Clusterings of the topics, with 
#     different number of clusters (c = {10, 17, 50})
# Author: Andreu Casas
#==============================================================================

# Load packages
library(broom)
library(ggplot2)
require(graphics)
library(grid)

# Load data with similarity score between all topics
cos_list <- read.csv("./data/cos_list.csv")

# Creating a similarity matrix
topics_n <- sqrt(length(cos_list$cos_sim))
db <- as.data.frame(matrix(nrow= topics_n, data = cos_list$cos_sim))
rownames(db) <- cos_list$t1[1:topics_n]
colnames(db) <- cos_list$t1[1:topics_n]

# Transforming cosine similarities into coordinates in order to plot them
#   into a 2-dimensions plane
loc <- cmdscale(1-db, eig=TRUE, k=2)
x <- loc$points[,1]
y <- loc$points[,2] 
sim_coord <- data.frame(x = x, y = y)

# Specifying the number of clusters of the clusterings to plot
cls <- c(10, 17, 50)

# Loading functions written for this specific plots
source("./06_extra_figure_2_functions.R")

# Creating a plot for each clusterings with differen number of clusters
c10_plot <- plot_clusters(sim_coord, 10)
c17_plot <- plot_clusters(sim_coord, 17)
c50_plot <- plot_clusters(sim_coord, 50)
  
# Combining the three 2-D plots into one plot
grid.newpage()
pushViewport(viewport(layout = grid.layout(9, 3)))   
print(c10_plot, vp = viewport(layout.pos.row = 1:9, layout.pos.col = 1))         
print(c17_plot, vp = viewport(layout.pos.row = 1:9, layout.pos.col = 2))
print(c50_plot, vp = viewport(layout.pos.row = 1:9, layout.pos.col = 3))
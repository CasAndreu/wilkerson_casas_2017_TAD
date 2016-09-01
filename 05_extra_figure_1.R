#==============================================================================
# 02_figure_2.R
# Purpose: reproduce Figure 2 of the paper.
# Author: Andreu Casas
#==============================================================================

# Load packages
library(ggplot2)

# Export dataset with the cosine similarities
cos_list <- read.csv("./data/cos_list.csv")

# Plot
ggplot(cos_list, aes(x = cos_sim)) + 
  geom_density(fill = "gray") +
  xlab("Cosine similarity") +
  ylab("") +
  scale_y_continuous(breaks = 0, labels =) +
  theme(panel.background = element_rect("white"))
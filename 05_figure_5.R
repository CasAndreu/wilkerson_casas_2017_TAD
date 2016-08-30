#==============================================================================
# 05_figure_5.R
# Purpose: reproduce Figure 5 of the paper. Metatopics of a 50 cluster model.
# Author: Andreu Casas
#==============================================================================

# Load packages
library(grid)
library(ggplot2)
library(dplyr)
library(tidyr)

# Load list of cosine similarities.
cos_list <- read.csv("./data/cos_list.csv")

# Using the 50 clusters model. 

# Loading the cluster classification
cl50 <- as.numeric(read.csv('data/clusters/cluster50.csv', header = F)[1,])

# Loading the top keywords for each cluster. 
# After I exported the list of top keywords for each cluster
#   (see the of "01_getting_models_and_clusters.py"), I manually examined them
#   and I gave them a metatopic label. This label is in the "issue" variable of
#   the following "clkw" dataset.
clkw <- read.csv("data/clusters_top_keywords/cluster50_w_metatopic_label.csv")
    # Adding 1 to the cluster number so that it's 1-50 instead of 0-49.
clkw$cluster <- clkw$cluster + 1

# A vector of all unique topics
all_topics <- unique(cos_list$t1)

# Initializing a "Model-Cluster" matrix. Each row contains information about 
#   a topic model (with differen k topics), and each column conatins information
#   about each of the clusters of the 50-cluster clustering. Each cell will 
#   indicate whether a topic-model has a topic in that cluster (=1) or not (=0).
cls_tm_mat <- as.data.frame(matrix(ncol = nrow(clkw), nrow = 17, data = 0))
colnames(cls_tm_mat) <- paste0("cl", seq(1,nrow(clkw),1))
rownames(cls_tm_mat) <- paste0("TM", seq(10,90,5))

# Filling out the "Model-Cluster" matrix. 
for (cl in 0:(nrow(clkw)-1)) {
  topics <- as.character(all_topics[which(cl50 == cl)])
  tm_vector <- paste0("TM", as.numeric(sapply(topics, function(x) 
    strsplit(x, "-")[[1]])[1,]))
  cls_tm_mat[unique(tm_vector), (cl + 1)] <- 1
}

# Reshaping the "Model-Cluster" matrix so it's easier to plot the data
cls_tm <- cls_tm_mat
cls_tm$models <- rownames(cls_tm)
cls_tm <- gather(cls_tm, cluster, topic_from_tm, -models)
cls_tm$topic_from_tm <- factor(cls_tm$topic_from_tm)
cls_tm$cluster <- as.integer(gsub("cl", "", as.character(cls_tm$cluster)))
cls_tm <- merge(cls_tm, clkw, by = "cluster")
cls_tm$cluster <- factor(cls_tm$cluster)
cls_tm <- arrange(cls_tm, issue)

# Releveling the factor variable "cluster" so that the "Melting Pot" cluster
#   is the last level and so it will appear at the top of the plot
lvls <- as.character(unique(cls_tm$cluster))
lvls <- lvls[-which(lvls == "1")]
lvls <- c(lvls, "1")
cls_tm$cluster <- factor(cls_tm$cluster, levels = lvls)

# Releveling the factor variable "issue" for the same reason
lvls_issue <- as.character(unique(cls_tm$issue))
lvls_issue <- lvls_issue[-which(lvls_issue == "Melting Pot")]
lvls_issue <- c(lvls_issue, "Melting Pot")
cls_tm$issue <- factor(cls_tm$issue, levels = lvls_issue)
cls_tm <- arrange(cls_tm, issue)

# Fixing a typo with one of the "issue" levels:
levels(cls_tm$issue)[2] <- "Agriculture"

# The "clkw" dataset conatins the top 15 keywords for each cluster. Too many
#   to plot. Only keeping the top 5. 
keywords <- NULL
for (i in 1:length(clkw$keywords)) {
  kws <- clkw$keywords[i]
  y <- strsplit(as.character(kws), split = ",")[[1]][1:4]
  top_kws <- paste0(y[1],",",y[2],",",y[3],",",y[4],"]")
  keywords <- c(keywords, top_kws)
}
clkw$topkws <- keywords

# FIGURE 5
# The plot get build in 3 parts:
#   1. The core of the figure: a tile (object "p")
#   2. The metatopics tags
#   3. The keywords for each topic
#  Run all the code below. The final command "grid.draw(gt)" builds the final
#   figure.
 
# If you want to exclude the "Melting Pot" cluster use this subset
cls_tm_final <- filter(cls_tm, issue !=  "Melting Pot")

pdf("~/Desktop/clusters_issues_topics2.pdf", width = 10, height = 6)
p <- ggplot(cls_tm_final, aes(models, factor(cluster, levels = ))) +
  geom_tile(aes(alpha = factor(topic_from_tm)), color = "white", fill = "gray", 
            size = 0.5) +
  #geom_tile(aes(fill=issue_color), alpha = 0.2) +
  ylab("") +
  scale_y_discrete(breaks = NULL) +
  theme(panel.background = element_rect(fill="white"),
        axis.text.x = element_text(angle=45, vjust=1, size=7, hjust=1),
        legend.position = "none",
        plot.margin = unit(c(1,12,1,7), "lines")) 
#unit(c(1,12.5,1,7)
cls <- 0
for (issue in unique(cls_tm_final$issue)) {
  cls_new <- length(unique(cls_tm_final$cluster[cls_tm_final$issue == issue]))
  p <- p +  geom_rect(size=0.1, fill=NA, colour="gray40",
                      xmin = 0.5, xmax = 17.5, 
                      ymin= (cls + 1) - 0.5, 
                      ymax = (cls + cls_new) + 0.5)
  cls <- cls + cls_new
}

cls <- 1
for (i in 1:length(unique(cls_tm_final$issue))){
  issue <- unique(cls_tm_final$issue)[i]
  cls_new <- length(unique(cls_tm_final$cluster[cls_tm_final$issue == issue]))
  p <- p + annotation_custom(
    grob = textGrob(label = unique(cls_tm_final$issue)[i], just = 1, 
                    gp = gpar(cex = 0.8)),
    ymin = as.numeric((cls-0.5) + (cls_new/2)),      # Vertical position of the textGrob
    ymax = as.numeric((cls-0.5) + (cls_new/2)),
    xmin = 0.4,         # Note: The grobs are positioned outside the plot area
    xmax = 0.4)
  cls <- cls + cls_new
}

z <- 1
for (cl in unique(cls_tm_final$cluster)){
  i <- as.numeric(as.character(cl))
  j <- which(levels(cls_tm_final$cluster) == cl)
  p <- p + annotation_custom(
    grob = textGrob(label = paste0(z,": ", clkw$topkws[i]),
                    hjust = 0, gp = gpar(cex = 0.7)),
    ymin = j,      # Vertical position of the textGrob
    ymax = j,
    xmin = 18,         # Note: The grobs are positioned outside the plot area
    xmax = 18)
  z <- z + 1
}

gt <- ggplot_gtable(ggplot_build(p)) 
gt$layout$clip[gt$layout$name == "panel"] <- "off"
grid.draw(gt)
dev.off()

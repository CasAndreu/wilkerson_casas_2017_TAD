#==============================================================================
# 04_figure_5.R
# Purpose: reproduce Figure 5 of the paper. Results for 21 robust Metatopics and
#          how they compare to the results for a single 50-topic model.
# Author: Andreu Casas
#==============================================================================

# Load packages
library(ggplot2)
library(dplyr)
library(tidyr)
library(grid)

# Load data with similarity score between all topics
cos_list <- read.csv("./data/cos_list.csv")

# Get the topic names from the similarity scores dataset
all_topics <- unique(cos_list$t1)

# Using the 50 clusters model
# Load the cluster classification
cl50 <- as.numeric(read.csv('data/clusters/cluster50.csv', header = F)[1,])

# Load the top keywords for each cluster. 
clkw <- read.csv("data/clusters_top_keywords/cluster50_w_metatopic_label.csv")

# Initialize database that will have the information for each metatopic (issues)
issues_db <- NULL

# Fill out the metatopic database.
for (issue in unique(clkw$issue)) {
  # select an issue/metatopic
  if (issue != "Melting Pot") {
    # which clusters are about that issue/metatopic
    issue_clusters <- clkw$cluster[clkw$issue == issue]
    # which topics (out of all 850 topics) are in those clusters
    topics <- as.character(all_topics[which(cl50 %in% issue_clusters)])
    # to which models (out of the 17 models) do these topics belong
    tm_vector <- as.numeric(sapply(topics, function(x) strsplit(x, "-")[[1]])[1,])
    # the topic number withing those models
    t_vector <- as.numeric(sapply(topics, function(x) strsplit(x, "-")[[1]])[2,])
    # initializing a database that will contain info about the percentage of 
    #   documents classified into a topic from that metatopic according to each
    #   topic-model
    partial_db <- as.data.frame(matrix(ncol = 5, nrow = 17))
    colnames(partial_db) <- c("dem", "rep", "dif", "tm", "issue")
    for (j in 0:16) { # Number of Topic-Models = 17
      z <- (j * 5) + 10
      if (!(z %in% tm_vector)) {
        next
      } else{
        data <- read.csv(paste0("data/classifications/classification_k", z, ".csv"),
                         header = FALSE)
        colnames(data) <- c("topic", "party", "bioguideId", "text")
        # which of the model's topics are in a cluster that belongs to the metatopic
        issue_topics <- t_vector[which(tm_vector %in% z)]
        dem_num <- nrow(data[data$party == "D" & (data$topic + 1) %in% issue_topics, ])
        rep_num <- nrow(data[data$party == "R" & (data$topic + 1) %in% issue_topics, ])
        dem_per <- dem_num / nrow(data[data$party == "D", ])
        rep_per <- rep_num / nrow(data[data$party == "R", ])
        dif_per <- rep_per - dem_per
        partial_db$dem[j + 1] <- dem_per
        partial_db$rep[j + 1] <- rep_per
        partial_db$dif[j + 1] <- dif_per
        partial_db$tm[j + 1] <- z
      }
      partial_db$issue <- as.character(issue)
    }
    issues_db <- rbind(issues_db, partial_db)
  }
  print(paste0("Done with issue: ", issue))
}

# Reshape and process the metatopics/issue database so that it's easier 
#   to plot the data

# Create a new column comparing how much attention Democrats and Republicans
#   paid to each topic. Multiply DEM's speeches by .55 and REP's by .45 to
#   account for the actual number of Dems and Reps in the sample
issues_db$attention <- (issues_db$dem * 0.55) + (issues_db$rep * 0.45)

# Get rid of the Unclear metatopic
issues_db_nounclear <- issues_db %>%
  filter(issue != "Unclear")

# Rename some metatopics to make the labels more clear
issues_db_nounclear$issue[issues_db_nounclear$issue == "Law"] <- "Law and Courts"
issues_db_nounclear$issue[issues_db_nounclear$issue == "Agruculture"] <- "Agriculture"

# Load a dataset with information about a single topic model of 50 topics.
#   To get this dataset we did the following:
#   - Looked at the most predictive features for each topic of the k=50 model 
#   - Labeled each topic according to its substantive content
#   - Aggregated topics for which we gave the same level (e.g. education topics)
#   - Calcualated for each topic the % of dem and rep speeches and the difference
issues_db50 <- read.csv("data/issues_db50.csv")

# Removing Unclear topic from the 50-topic model as well
issues_db50_nounclear <- issues_db50 %>%
  filter(issue != "Unclear")

# Adding to the 50-cluster and 50-topic databases a new variable indicating
#   that each row comes from that database. This is because then when we merge
#   the two we know where each row comes from.
issues_db50_nounclear$origin <- "tm50"
issues_db_nounclear$origin <- "cl50"

# For the 50-topic model, we don't want to plot the 2 topics that are not in
#   the robust 50-cluster model (History and Labor). Removing them from the
#   dataset.
issues_db50_nounclear <- issues_db50_nounclear %>%
  filter(issue != "History", issue != "Labor") %>%
  mutate(issue = as.character(issue))

# Merging the two datasets now
all_issues <- full_join(issues_db_nounclear, issues_db50_nounclear)
all_issues <- arrange(all_issues, issue)

# Standardize differences
all_issues$sum <- all_issues$rep + all_issues$dem
all_issues$dem_st <- all_issues$dem / all_issues$sum
all_issues$rep_st <- all_issues$rep / all_issues$sum
all_issues$dif_st <- all_issues$rep_st - all_issues$dem_st

# A database with the mean attention to the metatopics across models. Results
#   for the "robust" model.
issues_att <- issues_db_nounclear %>%
  group_by(issue) %>%
  summarize(dem = round(mean(dem, na.rm = TRUE) * 100, 1),
            rep = round(mean(rep, na.rm = TRUE) * 100, 1))
  
# FIGURE 7. We create the Figure in 2 steps:
#   a. The plot ("p")
#   b. We add two columns on the right side indicating Dems' and Reps' %
#   The command "grid.draw(gt)" at the end creates the Figure.

p <- ggplot(all_issues, aes(y = factor(issue), x = dif_st)) +
  geom_point(aes(size = origin, pch = origin, alpha = origin)) +
  scale_shape_manual(values = c(16,1)) +
  scale_size_manual(values = c(2,4)) +
  scale_alpha_manual(values = c(0.3,1)) +
  geom_vline(xintercept = 0) +
  xlab("+ Dem                                                           + Rep") +
  ylab("") +
  scale_x_continuous(breaks = seq(-1,1,0.25), 
                     labels = paste0(c(c(100, 75, 50, 25), seq(0, 100, 25)),"%")) +
  theme_bw() +
  theme(axis.text.y = element_text(size = 14),
        # axis.title.x = element_text(hjust = -0.005),
        plot.margin = unit(c(1,6,1,1), "lines"),
        legend.position = "none")

for (i in 1:nrow(issues_att)){
  if (i != 6) {
    d <- format(issues_att$dem[i], nsmall = 1)
    r <- format(issues_att$rep[i], nsmall = 1)
  }
  p <- p + annotation_custom(
    grob = textGrob(label = paste0((paste0(d, "%")),
                                   "  |  ", paste0(r,"%")), 
                    hjust = 0, gp = gpar(cex = 0.8)),
    ymin = i,      # Vertical position of the textGrob
    ymax = i,
    xmin = 1.15,         # Note: The grobs are positioned outside the plot area
    xmax = 1.15)
  if (i == nrow(issues_att)) {
    p <- p + annotation_custom(
      grob = textGrob(label = "     D         R", gp = gpar(cex = 0.9), hjust = 0.5),
      ymin = i + 1,      # Vertical position of the textGrob
      ymax = i + 1,
      xmin = 1.25,         # Note: The grobs are positioned outside the plot area
      xmax = 1.25)
  }
}

gt <- ggplot_gtable(ggplot_build(p))
gt$layout$clip[gt$layout$name == "panel"] <- "off"
grid.draw(gt)


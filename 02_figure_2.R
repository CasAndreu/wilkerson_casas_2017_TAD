#==============================================================================
# 02_figure_2.R
# Purpose: reproduce Figure 2 of the paper.
# Instructions: we first provide the code to calculate again the intracluster
#   similarities that we plot in Figure 4. If you don't want to calculate
#   them, go to straight to SECTION B, load the datasets from this repository, 
#   and replicate the plot. 
# Author: Andreu Casas
#==============================================================================

# Load packages
library(broom)
library(ggplot2)
require(graphics)
library(grid)

#==============================================================================
# SECTION A: Calculating the intracluster similarities (skip to SECTION B if
#   you simply want to load the instracluster-similarities datasets and 
#   replicate Figure 4)
#==============================================================================

# Load similarity matrix (see code in "03_figure_3.R" to see how the similarity
#   matrix is constructed)
db <- read.csv("./data/sim_matrix.csv")

# Calculating intra-cluster similatiry for each of the clusterings
#   EXCLUDING the metling_pot cluster
cls <- 5:99
intracluster <- as.data.frame(matrix(nrow=length(cls),ncol = 3))
colnames(intracluster) <- c('intra_sim', 'lwr', 'upr')
rownames(intracluster) <- cls
for (i in cls) {
  sims <- NULL
  # Loading a vector with the cluster classification
  d <- as.numeric(read.csv(paste0('./data/clusters/cluster',i,'.csv'), header = F)[1,])
  unique_cls <- unique(d)
  # Detecting the "melting_pot" cluster
  mp_cluster <- as.numeric(names(sort(table(d), decreasing = TRUE))[1])
  rest_unique_cls <- unique_cls[!(unique_cls %in% mp_cluster)]
  # Creating a vector of similarities between topics in the same cluster
  for (t in rest_unique_cls) {
    obs_i <- which(d == t)
    # For clusters with a large number of topics, randomply sampling 50
    if (length(obs_i) > 50) {
      obs_i <- sample(x = obs_i, size = 50, replace = TRUE)
    }
    for (j in obs_i) {
      for (z in obs_i) {
        if (j != z) {
          sims <- c(sims, db[j,z])
        }
      }
    }
  }
  ttest <- tidy(t.test(sims))
  intracluster$intra_sim[i -4] <- ttest$estimate
  intracluster$lwr[i -4] <- ttest$conf.low
  intracluster$upr[i -4] <- ttest$conf.high
}


# Calculating intra-cluster similatiry for each of the clusterings
#   INCLUDING the metling_pot cluster
intracluster2 <- as.data.frame(matrix(nrow=length(cls),ncol = 3))
colnames(intracluster2) <- c('intra_sim', 'lwr', 'upr')
rownames(intracluster2) <- cls
for (i in cls) {
  sims <- NULL
  d <- as.numeric(read.csv(paste0('data/clusters/cluster', i,'.csv'), header = F)[1,])
  for (t in unique(d)) {
    obs_i <- which(d == t)
    if (length(obs_i) > 50) {
      obs_i <- sample(x = obs_i, size = 50, replace = TRUE)
    }
    for (j in obs_i) {
      for (z in obs_i) {
        if (j != z) {
          sims <- c(sims, db[j,z])
        }
      }
    }
  }
  ttest <- tidy(t.test(sims))
  intracluster2$intra_sim[i -4] <- ttest$estimate
  intracluster2$lwr[i -4] <- ttest$conf.low
  intracluster2$upr[i -4] <- ttest$conf.high
}

#==============================================================================
# SECTION B: Calculating the intracluster similarities (skip to SECTION B if
#   you simply want to load the instracluster-similarities datasets and 
#   replicate Figure 4)
#==============================================================================

# Loading intracluster similarities. 
# NO NEED TO RUN THIS YOU HAVE RUN SECTION A

#============
intracluster <- read.csv("./data/intracluster_sims/intracluster.csv")
intracluster2 <- read.csv("./data/intracluster_sims/intracluster2.csv")
cls <- 5:99
#============

# Figure 4:
ggplot(intracluster, aes(x = cls, y = intra_sim)) + 
  geom_ribbon(aes(ymin = lwr, ymax = upr), alpha=0.6) +
  geom_ribbon(data = intracluster2, 
              aes(x = cls, y = intra_sim, ymin = lwr, ymax = upr),
              alpha = 0.4) +
  scale_x_continuous(breaks = seq(cls[1],cls[length(cls)],10)) +
  scale_y_continuous(breaks = seq(round(min(intracluster2$lwr),2),
                                  1, 0.05)) +
  xlab("Number of Clusters") +
  ylab("Av. intra-cluster cosine similarity") +
  # Labels for each cluster are manually added!
  annotate("text", x = 55, y = 0.65, size = 5, label = "Including Melting-Pot cluster") +
  annotate("text", x = 75, y = 0.95, size = 5, label = "Excluding Metling-Pot cluster") +
  theme(axis.text=element_text(size=14),
        axis.title=element_text(size=14),
        panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(colour = "gray90"))
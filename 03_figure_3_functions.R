#==============================================================================
# 03_figure_3_functions.R
# Purpose: functions used in the replication of Figure 3. 
# Author: Andreu Casas
#==============================================================================

# FUNCTIONS

# ... for each cluster, getting only 1 coord, where we put the cluster#
unique_cl_coord <- function(plot_db) {
  coord <- data.frame(cluster = NULL, x = NULL, y = NULL)
  for (j in 1:nrow(plot_db)) {
    obs <- plot_db[j,]
    obs$cluster <- obs$cluster + 1
    if (!(obs$cluster %in% coord$cluster)) {
      coord <- rbind(coord, obs[, 1:3])
    }
  }
  return(coord)
}


# ... a function to annotate the clusters number#
add_cluster_num <- function(cluster) {
  annotate("text", label = cluster$cluster, x = cluster$x, y = cluster$y,
           size = 7)
}
# ... the function that generates each individual clustering plot
plot_clusters <- function(sim_coord, c) {
  dataset <- sim_coord
  d <- as.numeric(read.csv(paste0('data/clusters/cluster_c', c, '.csv'), 
                           header = F)[1,])
  # Detecting which is the "melting pot" clusters: the largest one
  melting_pot <- names(which(table(d) == max(table(d))))
  dataset$cluster <- d
  dataset$mp_cluster <- 0
  dataset$mp_cluster[which(dataset$cluster == melting_pot)] <- 1
  # Specifying colors for the clusters
  plot_colors <- rainbow(i)
  cluster_levels <- levels(factor(dataset$cluster))
  level_index <- which(cluster_levels == melting_pot)
  plot_colors[level_index] <- "gray"
  # Specifying a unique coordinate per clusters: where to plot the cluster #
  coord <- data.frame(cluster = NULL, x = NULL, y = NULL)
  for (j in 1:nrow(dataset)) {
    obs <- dataset[j,]
    if (!(obs$cluster %in% coord$cluster)) {
      coord <- rbind(coord, obs[, 1:3])
    }
  }
  # The plot object with the coordinates for the cluster numbers#
  cl_num <- lapply(1:nrow(coord), 
                   function(x) add_cluster_num(coord[x,]))
  # The plot
  p <- ggplot(dataset[,], aes(x = x, y = y, col = factor(cluster))) +
    geom_point(aes(shape = factor(mp_cluster), size = factor(mp_cluster))) +
    labs(x = "", y = "") +
    scale_x_continuous(breaks = NULL) +
    scale_y_continuous(breaks = NULL) +
    theme(legend.position="none") +
    scale_shape_manual(values=c(19, 21)) +
    scale_size_manual(values = c(2,1)) +
    scale_color_manual(values = plot_colors) +
    ggtitle(paste0("# Clusters = ", c)) +
    cl_num
  return(p)
}

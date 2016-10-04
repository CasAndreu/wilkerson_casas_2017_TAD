#==============================================================================
# 07_validation.R
# Purpose: code used for validating one of the metatopics (Agriculture) in the
#          online_appendix.pdf"
# Author: Andreu Casas
#==============================================================================

# Load packages
library(rio)
library(XLConnect)
library(dplyr)
library(ggplot2)

#==============================================================================
# SECTION A: Creating the dataset with members-district-level data about the
#             percentage of people in each district working on Agriculture and
#             the percentage of speeches from the House repr from that district
#             that were about the Agriculture metatopic.
#           The resulting dataset is already in the "data" directory:
#             "agr_memb.csv". Feel free to scape to SECTION B to simply 
#             replicate the figure in the Online Appendix. 
#==============================================================================

# In the directory "./data/cong_districts_data" there a set of Excel files, one
#   file per state, with numerous socio-economic information at the district 
#   level from the '2014 American Community Survey 1-year estimates' and 
#   '2014 County Business Patterns' (you can access the original data in 
#   'http://www.census.gov/mycd/'). 

# Each file is a state, and each tab within the Excel is a district. Go through
#   all the files and tabs to collect district-level data about the percentage
#   of the population that works on 'Agriculture, Forestry, Fishing, Hunting,
#   and Mining'.

# Lisf of files 
cong_files <- list.files("data/cong_districts_data")

# Empty db that I will fill with congressional district data
all_districts_data <- NULL

# Looping through the files, pulling the data, and filling the main db
for (f in cong_files){
  state <- strsplit(x = as.character(f), split = ".", fixed = TRUE)[[1]][1]
  state <- strsplit(x = as.character(state), split = "(", fixed = TRUE)[[1]][1]
  state <- gsub("_cd_", "", state)
  state <- gsub("_", " ", state)
  if (grepl(".xlsx", f)) {
    error <-  FALSE
    full_spreadsheet <- loadWorkbook(paste0("data/cong_districts_data/", f))
    district <- 1
    while(!error) {
      try_output <- try(
        district_sheet <- readWorksheet(full_spreadsheet, 
                                        sheet = paste0("District ", district))
      )
      if (class(try_output) == "data.frame") {
        agr_row <- which(grepl("Agriculture, forestry, fishing and hunting, and mining", 
                               district_sheet[,1]))
        agr_pop_district <- district_sheet[agr_row, 2]
        all_pop_district <- district_sheet[3, 2]
        agr_pop_district <- as.numeric(gsub(",", "", agr_pop_district))
        all_pop_district <- as.numeric(gsub(",", "", all_pop_district))
        new_data_row <- data.frame(
          state = state,
          district = district,
          total_pop = all_pop_district,
          agr_pop = agr_pop_district,
          agr_pop_perc = agr_pop_district / all_pop_district
        )
        all_districts_data <- rbind(all_districts_data, new_data_row)
        district <- district + 1
      } else {
        error <- TRUE
      }
    }
  } else {
    district_sheet <- import(paste0("data/cong_districts_data/", f))
    agr_row <- which(grepl("Agriculture, forestry, fishing and hunting, and mining", 
                           district_sheet[,1]))
    agr_pop_district <- district_sheet[agr_row, 2]
    all_pop_district <- district_sheet[3, 2]
    agr_pop_district <- as.numeric(gsub(",", "", agr_pop_district))
    all_pop_district <- as.numeric(gsub(",", "", all_pop_district))
    new_data_row <- data.frame(
      state = state,
      district = "at_large",
      total_pop = all_pop_district,
      agr_pop = agr_pop_district,
      agr_pop_perc = agr_pop_district / all_pop_district
    )
    all_districts_data <- rbind(all_districts_data, new_data_row)
  }
}

# Reading in a file with states abbreviation and full name equivalence
source("07_02_validation_state_abbrev.R")
abbrev_df <- data.frame(state = as.character(state_abbrev),
                        abbrev = names(state_abbrev))

# Adding state abbreviation to the dataset
distr_data <- left_join(all_districts_data, abbrev_df)
distr_data <- mutate(distr_data, st_dist = paste0(abbrev, "-", district))
distr_data <- rename(distr_data, full_state = state, state = abbrev)

# This is how I have it in the other dataset with members data that I will now
#   merge to this one
distr_data$district[distr_data$district == "at_large"] <- 1 
distr_data$district <- as.integer(distr_data$district)
  
# Reading in data on members of congress
members <- read.csv("data/congress_data.csv")

memb <- members %>%
  filter(chamber == "House") %>%
  select(last_name, state, district, thomas_id, id)

memb$id <- as.character(memb$id)
memb$thomas_id <- as.character(memb$thomas_id)
memb$state <- as.character(memb$state)
distr_data$state <- as.character(distr_data$state)
memb$district <- as.character(memb$district)
distr_data$district <- as.character(distr_data$district)
agr_memb <- left_join(distr_data, memb)

# Knowing the relative attention that each member paid to topics in the 
#   agriculture meta-topic, averaging topics across TMs.
clustering50 <- as.numeric(read.csv('data/clusters/cluster50.csv', header = F)[1,])
clkw <- read.csv("data/clusters_top_keywords/cluster50_w_metatopic_label.csv")

# Similarity scores
data <- read.csv('data/final_simsList.csv')

# Getting the topic names from the similarity scores dataset
all_topics <- data$t1[1:850]

levels(clkw$issue)[2] <- "Agriculture"

issue_clusters <- clkw$cluster[clkw$issue == "Agriculture"]
topics <- as.character(all_topics[which(clustering50 %in% issue_clusters)])
tm_vector <- as.numeric(sapply(topics, function(x) strsplit(x, "-")[[1]])[1,])
t_vector <- as.numeric(sapply(topics, function(x) strsplit(x, "-")[[1]])[2,])
for (j in tm_vector) {
  model <- paste0("k", (j * 5) + 5)
  agr_memb[, model] <- NA
  data <- read.csv(paste0("data/classifications/classification_", model,".csv"),
                   header = FALSE)
  colnames(data) <- c("topic", "party", "bioguideId", "text")
  issue_topics <- t_vector[which(tm_vector %in% j)]
  for (m in unique(data$bioguideId)) {
    m <- as.character(m)
    total <- nrow(data[data$bioguideId == m,])
    agr <- nrow(data[data$bioguideId == m & data$topic %in% issue_topics, ])
    agr_rel <- agr/total
    agr_memb[which(agr_memb$id == m), model] <- agr_rel
  }
}

# Calculating the average percentage of speeches on the metatopic agriculture
#   accross topic models that had a topic of this metatopi
mean_agr_speeches <- sapply(1:nrow(agr_memb), function(x) 
  mean(as.numeric(agr_memb[x, 10:14]), na.rm = TRUE))
mean_agr_speeches[is.na(mean_agr_speeches)] <- NA
mean_agr_speeches <- round(mean_agr_speeches, 3)
agr_memb$agr_speeches <- mean_agr_speeches

#==============================================================================
# SECTION B: Replication of the validation figure in the Appendix. No need
#             to load the "agr_memb" dataset if you already run SECTION A.
#==============================================================================

#=======
agr_memb <- read.csv("./data/agr_memb.csv")
#=======

# Figure showing the validation of the topic Agriculture in the Online Appendix
ggplot(agr_memb, aes(x = agr_pop_perc, y = agr_speeches)) +
  geom_point() +
  geom_smooth(method = "lm", color = "black") +
  ylab("Speeches on Agriculture (% of the total speeches)") +
  xlab("% of the district population working in Agriculture, Forestry, Fishing, Hunting and Minig") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(colour = "gray90"))



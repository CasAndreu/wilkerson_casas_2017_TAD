#==============================================================================
# 01_getting_models_and_clusters.py
# Purpose: fitting multiple LDA models to one-minute floor speeches and then
#   clustering the resulting topics.
# Details: implements a Python module (rlda) written for this purpose.
# Author: Andreu Casas
#==============================================================================

# Loading modules
import rlda
import random
import os
import csv

# Seting seed
random.seed(123)

# Importing the 9,704 one-minute floor speeches given during the 113th Congress
#   from the 'rlda' module
data = rlda.speeches_data

# Pulling only the speeches from the data
speeches = [d["speech"] for d in data]

# Pre-processing:
#        - Parsing speeches into words
#        - Removing punctuation
#        - Removing stopwords
#        - Removing words shorter than 3 characters
#        - Stemming remaining words (Porter Stemmer)
speeches = speeches[:100]
clean_speeches = rlda.pre_processing(speeches)

# Creating an RLDA object so that we can implement all functions in the
#   'rlda' module
robust_model = rlda.RLDA()

# Transforming "clean" speeches into a Term Document Matrix
robust_model.get_tdm(clean_speeches)

# Fitting multiple LDA models to the speeches (TDM) 
k_list = range(10,20,5) #list with #topics (k) for the models we want to fit
n_iter = 50 #number of iteration when estimating the  models
robust_model.fit_models(k_list = k_list, n_iter = n_iter)

# LDA models can are often used to classify documents into topics
# Getting the document classifications by each estimated model
classifications = []
for m in robust_model.models_list:
    doc_topic_pr = m.doc_topic_
    docs = []
    for i in range(0, len(doc_topic_pr)):
        doc_dic = {}
        doc = doc_topic_pr[i]
        list_doc = list(doc)
        top_topic = (list_doc.index(max(list_doc)) + 1)
        doc_dic["topic"] = top_topic
        doc_dic["party"] = data[i]["party"]
        doc_dic["bioguide_id"] = data[i]["bioguide_id"]
        doc_dic["clean_text"] = clean_speeches[i]
        docs.append(doc_dic)
    classifications.append(docs)

# Exporting CSV files for each model classification
path = "/Users/andreucasas/Desktop/wilkerson_casas_2016_TAD/"
dir_name = "data/classifications/"
if not os.path.isdir(path + dir_name):
    os.mkdir(path + dir_name)
for i in range(0, len(classifications)):
    classification = classifications[i]
    file_name = "classification_k" + str(k_list[i]) + ".csv"
    f = open(path + dir_name + file_name, "wb")
    w = csv.DictWriter(f, classification[0].keys())
    w.writerows(classification)
    f.close()
    
# Calculating pairwise cosine similarity between al topics from all models

# Creating a cosine similarity matrix. Dimensions = TxT where T = #topics
robust_model.get_cosine_matrix()

# Creating a list with the cosine similarities. Dimensions = 1x(T^2)
robust_model.get_cosine_list()

# Saving the list of cosine similarities into a CSV
robust_model.save_cosine_list_to_csv(path + "data/cos_list.csv")

# Getting the top 50 predictive features (words) for each topic
robust_model.get_all_ftp(features_top_n = 50)

# Clustering the topics based on the cosine similarities by using Spectral
#   clustering.
# Trying several n-clusterings

clusters_list = []
clusters_fcps_list = []

clusters_n = range(5,10,1) #list of number of clusters to try out
for n in clusters_n:
    clusters = robust_model.cluster_topics(clusters_n = n)
    # features_top_n = top most predictive features for each cluster that we
    #   want to keep
    fcps = robust_model.get_fcp(clusters, features_top_n = 15)
    clusters_list.append(clusters)
    clusters_fcps_list.append(fcps)


    
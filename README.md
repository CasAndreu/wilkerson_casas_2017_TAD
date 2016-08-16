# wilkerson_casas_2016_TAD
Replication material for the paper by John Wilkerson and Andreu Casas on Text as Data at the Annual Review of Political Science:

Wilkerson, John and Andreu Casas. 2016. "Large-scale Computerized Text Analysis in Political Science: Opportunities and Challenges." *Annual Review of Political Science*, VV:p-p.

## Instructions

a. `01_getting_models_and_clusters.py`: This is a python script that does the following:
  - Reads and pre-processes 9,704 one-minute floor speehces from the 113th Congress
  - Estimates 17 [LDA](https://pypi.python.org/pypi/lda) topic models with different numbers of `k` topics (k = {10, 15, ..., 90})
  - Calculates the pairwise cosine similarity (n = 722,500) between all topics (n = 850) from the 17 models.
  - Uses [Spectal Clustering](http://scikit-learn.org/stable/modules/clustering.html#spectral-clustering) and the cosine similarity scores to cluster topics into `c` number of groups (c = {5, 10, ..., 95})

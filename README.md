# Wilkerson & Casas (2017) Text As Data *ARPS*
Replication material for the paper by John Wilkerson and Andreu Casas on Text as Data at the Annual Review of Political Science:

Wilkerson, John and Andreu Casas. 2017. "Large-scale Computerized Text Analysis in Political Science: Opportunities and Challenges." *Annual Review of Political Science*, 20:p-p. (*forthcoming*)

---

## Instructions

- Clone the repository
- Open the `R` project `wilkerson_casas_2017_TAD` in `RStudio`, or set up this repository as your working directory in `R`
- The `data` directory contains all the final datasets we used in the paper
- The text and metadata of the one-minute floor speeches can be found in the python module we developed to estimate Robust Latent Dirichlet Allocation models: [rlda](https://github.com/CasAndreu/rlda)
- The `01_getting_models_and_clusters.py` reproduces the construction of the final datasets
- Scripts `02` to `05` replicate Figures in the paper
- Scripts `06` and `07` create additional Figures that ended up not making it to the final verison paper
- Figure 1 is from another paper by [Chuang et al. (2015)](http://www.aclweb.org/anthology/N15-1018): it's Figure 3 at the top of p. 188.
- Figure 2 is simply a diagram and we do not include code to replicate it
- The `online_appendix.pdf` conatins a list of top terms for the 50 clusters and extra information about the validation of the agriculture metatopic.

---


**A**. [`01_getting_models_and_clusters.py`](https://github.com/CasAndreu/wilkerson_casas_2017_TAD/blob/master/01_getting_models_and_clusters.py)

**Only run this script if you want to generate again the main datasets used in the article.** Skip otherwise: the `data` directory in this repository already contains the datasets needed to replicate the article's Figures. However, since algorithms randomly choose starting points when estimating topic models and clusters, the topic and cluster numbers that you get may be different than the ones we use in the other scripts. To exactly replicate the figures in the paper, simply run the other scripts.

This python script that does the following:
  - Reads and pre-processes 9,704 one-minute floor speehces from the 113th Congress.
  - Estimates 17 [LDA](https://pypi.python.org/pypi/lda) topic models with different numbers of `k` topics (`k` = {10, 15, ..., 90}) 
  - Classifies the speeches 17 times according to the models and saves the classifications in `csv` fromat in the `data/classifications` directory.
  - Calculates the pairwise cosine similarity (n = 722,500) between all topics (n = 850) from the 17 models and saves the similarity scores in `csv` format: `cos_list.csv`
  - Uses [Spectral Clustering](http://scikit-learn.org/stable/modules/clustering.html#spectral-clustering) and the cosine similarity scores to cluster topics into `c` number of clusters (`c` = {5, 10, ..., 95}). Saves the resulting clusters in the `data/clusters` directory.
  The script uses a `python` module initially written for this paper: [rlda](https://github.com/CasAndreu/rlda) (Robust Latent Dirichlet Allocation)
  
**B**. [`02_figure_2.R`](https://github.com/CasAndreu/wilkerson_casas_2017_TAD/blob/master/02_figure_2.R): Replication of Figure 2 of the paper.
<p align="center">
  <img src="images/intra_including_excluding.png" style="width: 200px;"/>
</p>

**C**. [`03_figure_4.R`](https://github.com/CasAndreu/wilkerson_casas_2017_TAD/blob/master/03_figure_4.R): Replication of Figure 4 of the paper.
<p align="center">
  <img src="images/clusters_issues_topics2.png" style="width: 200px;"/>
</p>

**D**. [`04_figure_5.R`](https://github.com/CasAndreu/wilkerson_casas_2017_TAD/blob/master/04_figure_5.R): Replication of Figure 5 of the paper.
<p align="center">
  <img src="images/issues_results2.png" style="width: 200px;"/>
</p>


**E**. [`05_extra_figure_1.R`](https://github.com/CasAndreu/wilkerson_casas_2017_TAD/blob/master/05_extra_figure_1.R): Figure showing the density of all cosine similarities.
<p align="center">
  <img src="images/intra_density_final.png" style="width: 200px;"/>
</p>

**F**. [`06_extra_figure_2.R`](https://github.com/CasAndreu/wilkerson_casas_2017_TAD/blob/master/06_extra_figure_2.R): Figure showing three Spectral Clusterings of the topics, with different number of clusters (`c` = {10, 17, 50})
<p align="center">
  <img src="images/three_clustering.png" style="width: 200px;"/>
</p>

**G**. [`07_01_validation.R`](https://github.com/CasAndreu/wilkerson_casas_2017_TAD/blob/master/07_01_validation.R): Code used for the validation of the metatopic Agriculture in the Online Appendix. In the data directory there is also a dataset (`agr_memb.csv`) with district-member-level data about the percentage of district population working on the agricultural sector and percentage of representatives' speeches on Agriculture. 

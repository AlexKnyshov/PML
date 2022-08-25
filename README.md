# PML
Phylogenetic Machine Learning and Sequence Simulations

Add contents here

## Simulation

### Species tree simulation

#### Empirical species trees

##### Infer trees of empirical datasets in IQ-TREE

For consistency, as well as because not all studies release the tree files, the trees were inferred denovo based on provided alignments

##### Prepare the starting trees for simulation

First create a folder for empirical simulations

```
mkdir -p simulations/empirical/fong/1/
mkdir -p simulations/empirical/wickett/1/
mkdir -p simulations/empirical/mcgowen/1/
mkdir -p simulations/empirical/liu/1/
```

Place the inferred phylograms for each dataset in the corresponding `1` folder under the name of `inference.treefile`.

Then run the following code in R:

```
library(ape)
library(ggplot2)
library(ggtree)
```

Adjust the path to `modified.write.tree2.R`:
```
source("/home/alex/tools/PML/simulation/modified.write.tree2.R")
assignInNamespace(".write.tree2", .write.tree2, "ape")
```

Adjust the paths to ML species trees for each dataset.

Empirical species tree 1 (Fong et al.):
```
fong_tree <- read.tree("simulations/empirical/fong/1/inference.treefile")
fong_tree <- root(fong_tree, outgroup = "Danio")
ggtree(fong_tree) + theme_tree2()
```
Check the tree rooted correctly. Then transform to ultrametric and rescale to correct number of generations
```
fong_tree_um <- chronos(fong_tree)
class(fong_tree_um) <-"phylo"
fong_scale <- 435000000/10
fong_tree_um <- rescale(fong_tree_um, model = "depth", fong_scale)
ggtree(fong_tree_um) + theme_tree2()
```
Check the tree is correct. Then replace labels with numbers as in regular SimPhy simulations and strip off the node labels (if any). Write out the tree and seeds for subsequent dataset parameter simulations.
```
fong_tree_um$tip.label <- as.character(1:length(fong_tree_um$tip.label))
fong_tree_um$node.label <- NULL
write.tree(fong_tree_um, "simulations/empirical/fong/1/s_tree.trees", digits=8)
write(c(20001,10000),"simulations/empirical/fong/generate_params.txt")
```

Analogously process other datasets:

Empirical species tree 2 (Wickett et al.):
```
wickett_tree <- read.tree("simulations/empirical/wickett/1/inference.treefile")
wickett_tree <- root(wickett_tree, outgroup = "Pyramimonas_parkeae")
wickett_tree_um <- chronos(wickett_tree)
class(wickett_tree_um) <-"phylo"
wickett_scale <- 1200000000/5
wickett_tree_um <- rescale(wickett_tree_um, model = "depth", wickett_scale)
wickett_tree_um$tip.label <- as.character(1:length(wickett_tree_um$tip.label))
wickett_tree_um$node.label <- NULL
write.tree(wickett_tree_um, "simulations/empirical/wickett/1/s_tree.trees", digits=8)
write(c(20002,100000),"simulations/empirical/wickett/generate_params.txt")
```

Empirical species tree 3 (McGowen et al.):
```

mcgowen <- read.nexus("simulations/empirical/mcgowen/1/cetTree1.tre")
mcgowen_um <- chronos(mcgowen)
class(mcgowen_um) <-"phylo"
mcgowen_scale <- 75000000/20
mcgowen_um <- rescale(mcgowen_um, model = "depth", mcgowen_scale)
mcgowen_um$tip.label <- as.character(1:length(mcgowen_um$tip.label))
write.tree(mcgowen_um, "simulations/empirical/mcgowen/1/s_tree.trees", digits=8)
write(c(20003,1000),"simulations/empirical/mcgowen/generate_params.txt")
```

Empirical species tree 4 (Liu et al.):
```
liu_tree <- read.tree("simulations/empirical/liu/1/inference.treefile")
liu_tree <- root(liu_tree, outgroup = "danio_rer")
liu_tree_um <- chronos(liu_tree)
class(liu_tree_um) <-"phylo"
liu_scale <- 435000000/10
liu_tree_um <- rescale(liu_tree_um, model = "depth", liu_scale)
liu_tree_um$tip.label <- as.character(1:length(liu_tree_um$tip.label))
liu_tree_um$node.label <- NULL
write.tree(liu_tree_um, "simulations/empirical/liu/1/s_tree.trees", digits=8)
write(c(20004,10000),"simulations/empirical/liu/generate_params.txt")
```

#### Random species trees

Make the folder for random species tree simulations
```
mkdir simulation/random
cd simulation/random/
```
Run the SimPhy wrapper to simulate each dataset
```
Rscript ~/tools/PML/simulation/run_sptree_SimPhy.R
```

### Locus alignments simulation

For each simulated dataset, navigate into corresponding dataset directory, for ex
```
cd simulations/empirical/fong/
```

Then run the following commands (adjust the paths to scripts accordingly):
```
Rscript ~/tools/PML/simulation/generate_sim_properties.R
Rscript ~/tools/PML/simulation/run_SimPhy.R sptree.nex df.csv
Rscript ~/tools/PML/simulation/prep_INDELible.R ./gene_trees.tre ./df.csv
cd alignments1
cp ../control.txt .
~/tools/INDELibleV1.03/src/indelible
cp ../controlCDS.txt ./control.txt
~/tools/INDELibleV1.03/src/indelible
cd ../
Rscript ~/tools/PML/simulation/post_INDELible.R alignments1/ df.csv
```

Assess features like pairwise distance, ILS levels, etc.

Repeat for all datasets (species trees)

## Assess loci properties

### Run assessment programs

For each simulated dataset, transfer the folder `alignments2` to a similarly structured folder on a cluster with slurm. Additionally transfer scripts / clone the repo to the cluster as well. Make sure that `MAFFT`, `AMAS`, `IQ-TREE2`, `FastSP`, and `HyPhy` are installed, and correct paths/modules in the submission scripts as needed.

Then, in a given dataset directory (where the folder `alignments2` is located) run the prep script to set up necessary folders:
```
sbatch prep.sh
```

When complete, submit the alignment job (8 array elements correspond to 2000 files split into 250 file bins):
```
sbatch --array=1-8 mafft.sh
```

When complete, submit jobs to run AMAS (properties), IQ-TREE (trees), and FastSP (alignment accuracy)
```
sbatch run_amas.sh
sbatch --array=1-8 iqtree_array.sh
sbatch run_FastSP.sh
sbatch iqtree_concat.sh
```

When complete, submit a job to prepare species tree for each locus to assess rates with HyPhy
```
sbatch prune_rescale_species_tree.sh
```

When complete, submit jobs to run HyPhy to assess site rates for each locus (since separate trees were estimated for Train and Test datasets, rate assessments are done separately as well):
```
sbatch --array=1-4 rate_assessment_Train.sh
sbatch --array=5-8 rate_assessment_Test.sh
```

When complete, download/assemble together the following files/folders for the final assessment steps:
```
inferred_gene_trees*
pruned_species_trees*
amas_output?.txt
rate_assessment
alignments3
fastsp_output.csv
iqtree_concattree/inference*.treefile
```
An example of the `rsync` command would be:
```
rsync -avzr andromeda:/path_to_dataset/inferred_gene_trees* local_path
```

### Run assessment script

For simulation datasets the true trees are known. So instead of using pruned and rescaled inferred trees, we prepare the true simulated trees.

For each dataset, run the following commands:

Run this command to prepare the true species trees for feature assessments:
```
Rscript ~/tools/PML/feature_assessment/prune_tree_simul.R 1/s_tree.trees inferred_gene_trees_Train.tre pruned_simul_trees_Train.tre
Rscript ~/tools/PML/feature_assessment/prune_tree_simul.R 1/s_tree.trees inferred_gene_trees_Test.tre pruned_simul_trees_Test.tre
```

When complete, run the main feature assessment script
```
Rscript ~/tools/PML/feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Train.tre inferred_gene_trees_Train.txt pruned_simul_trees_Train.tre amas_output3.txt ./rate_assessment/ ML_train.txt ./fastsp_output.csv
Rscript ~/tools/PML/feature_assessment/assess_gene_properties.R ./alignments3/ inferred_gene_trees_Test.tre inferred_gene_trees_Test.txt pruned_simul_trees_Test.tre amas_output3.txt ./rate_assessment/ ML_test.txt ./fastsp_output.csv
```

Output files are `ML_train.txt` and `ML_test.txt` respectively. These files are used for some of the downstream interrogations, however, to train / use the machine learning model, ML_train/test file for all datasets are combined together and certain columns are excluded (for ex, wRF column is excluded when training using RF as the proxy for phylogenetic utility).

### Assessment summary

Read the dataset trees
```
ds_path_vector <- c(list.files(path="simulations/empirical", pattern="", full.names=T, recursive=FALSE),
                    paste0("simulations/random/ds_", 1:16))
ds_name_vector <- c(list.files(path="simulations/empirical", pattern="", full.names=F, recursive=FALSE),
                    paste0("ds_", 1:16))

sptrees <- list()
branchdata <- data.frame()
#for (f in 1:20) {
  sptrees[[f]] <- read.tree(paste0(ds_path_vector[f],"/1/s_tree.trees"))
  branchdata <- rbind(branchdata, data.frame(brdep = node.depth.edgelength(sptrees[[f]])[sptrees[[f]]$edge[,1]]/max(node.depth.edgelength(sptrees[[f]])),
                                             brlen = sptrees[[f]]$edge.length/max(node.depth.edgelength(sptrees[[f]]))))
}
class(sptrees) <- "multiPhylo"
```

Plot the species trees of each dataset (for the supplementary Fig)
```
pS1 <- ggtree(sptrees) + theme_tree2() + facet_wrap(~.id, scales="free")
levels(pS1$data$.id) <- c("Fong et al.", "Liu et al.", "McGowen et al.", "Wickett et al.", paste0("Random ", 1:16))
pS1 +
  theme(axis.text.x = element_text(size=6.5),
        panel.spacing.x = unit(10, "mm"),
        panel.spacing.y = unit(5, "mm"),
        plot.margin = unit(c(5,5,5,5), "mm")) +
  scale_x_continuous(expand = c(0,0))
```

And check node height / branch length distributions across all datasets
```
library(ggExtra)
ggMarginal(ggplot(branchdata,aes(log(brlen), brdep)) + geom_point() + theme_bw())
ggMarginal(ggplot(branchdata,aes(brlen, brdep)) + geom_point() + theme_bw())
```

Now read the properties of all loci of all datasets. These include both true values of simulated properties (not used in the machine learnig model) and assessed values (used in the ML):
```
#create data frame to populate
combo_simul_eval_df <- data.frame()
#iterate over datasets
for (f in 1:length(ds_name_vector)){
  #read main simulated properties
  simul_df <- read.csv(paste0(ds_path_vector[f],"/df.csv"), header = T)[,2:21]
  simul_df$loci <- paste0(simul_df$loci, ".fas")

  #read simulated substitution model properties
  model_df <- read.csv(paste0(ds_path_vector[f],"/df2.csv"), header = T)[,2:8]
  model_df$loci <- paste0(model_df$loci, ".fas")

  #merge and compute additional variables from existing
  simul_df <- merge(simul_df, model_df, by="loci")
  nmissing_taxa <- sapply(simul_df$taxa_missing, function(x) length(eval(parse(text=x))))
  nremaining_taxa <- sapply(simul_df$remaining_taxa, function(x) length(eval(parse(text=x))))
  simul_df$prop_missing_taxa <- nmissing_taxa/(nmissing_taxa+nremaining_taxa)
  simul_df$prop_paralogy <- sapply(simul_df$paralog_cont, function(x) eval(parse(text=x)))/(nmissing_taxa+nremaining_taxa)
  simul_df$prop_contamination <- sapply(simul_df$cont_pair_cont, function(x) eval(parse(text=x)))/(nmissing_taxa+nremaining_taxa)

  #read assessed properties table for the training subsets
  ML_train_df <- read.table(paste0(ds_path_vector[f],"/ML_train.txt"), header = T)
  ML_train_df$MLset <- "train"

  #read assessed properties table for the testing subsets and merge with the previous
  ML_test_df <- read.table(paste0(ds_path_vector[f],"/ML_test.txt"), header = T)
  ML_test_df$MLset <- "test"
  ML_df <- rbind(ML_train_df, ML_test_df)
  
  #if assessed, read the gene tree distance btw aligned and unaligned input loci
  #this looks at how alignment error manisfested itself in gene trees
  genetreedf <- read.csv(paste0(ds_path_vector[f],"/gtreedist.csv"), header = T)
  colnames(genetreedf)[2:3] <- c("gtrRFsim", "gtrwRFsim")

  #merge all
  combo_df <- merge(simul_df, ML_df, by.x="loci", by.y="locname")
  combo_df <- merge(combo_df, genetreedf, by.x="loci", by.y="locname")
  combo_df[,1] <- paste0(ds_name_vector[f], "_", combo_df[,1])
  combo_df$dataset <- ds_name_vector[f]
  combo_simul_eval_df <- rbind(combo_simul_eval_df,combo_df)
}
```

Create Fig 1
```
p2_1 <- ggplot(combo_simul_eval_df,aes(x=abl, y=robinson)) +
  		geom_density_2d_filled() +
  		theme_bw()+
  		theme(legend.position = "none") +
  		ylab("RF similarity") + xlab("Simulated gene tree substitution rate")
p2_2 <- ggplot(combo_simul_eval_df,aes(x=loclen, y=robinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none") +
        ylab("RF similarity") + xlab("Simulated locus length")
p2_3 <- ggplot(combo_simul_eval_df,aes(x=lambdaPS, y=robinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none") +
        ylab("RF similarity") + xlab("Simulated phylogenetic signal (Pagel's lambda)")
p2_4 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_contamination, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=robinson)) +
        geom_boxplot() +
        theme_bw()+
        theme(legend.position = "none",
              axis.text.x = element_text(angle = 45,vjust = 1,hjust=1)) +
        ylab("RF similarity") + xlab("Simulated cross-contamination proportion")
p2_5 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_paralogy, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=robinson)) +
        geom_boxplot() +
        theme_bw()+
        theme(legend.position = "none",
              axis.text.x = element_text(angle = 45,vjust = 1,hjust=1)) +
        ylab("RF similarity") + xlab("Simulated paralogy proportion")
p2_6 <- ggplot(combo_simul_eval_df,aes(x=abl, y=wrobinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none") +
        ylab("wRF similarity") + xlab("Simulated gene tree substitution rate")
p2_7 <- ggplot(combo_simul_eval_df,aes(x=loclen, y=wrobinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none") +
        ylab("wRF similarity") + xlab("Simulated locus length")
p2_8 <- ggplot(combo_simul_eval_df,aes(x=lambdaPS, y=wrobinson)) +
        geom_density_2d_filled() +
        theme_bw()+
        theme(legend.position = "none") +
        ylab("wRF similarity") + xlab("Simulated phylogenetic signal (Pagel's lambda)")
p2_9 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_contamination, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=wrobinson)) +
        geom_boxplot() +
        theme_bw()+
        theme(legend.position = "none",
              axis.text.x = element_text(angle = 45,vjust = 1,hjust=1)) +
        ylab("wRF similarity") + xlab("Simulated cross-contamination proportion")
p2_10 <- combo_simul_eval_df %>%
        mutate( bin=cut_width(prop_paralogy, width=0.01, boundary=0) ) %>%
        ggplot(aes(x=bin, y=wrobinson)) +
        geom_boxplot() +
        theme_bw()+
        theme(legend.position = "none",
              axis.text.x = element_text(angle = 45,vjust = 1,hjust=1)) +
        ylab("wRF similarity") + xlab("Simulated paralogy proportion")
grid.arrange(p2_1, p2_2, p2_3, p2_4, p2_5,
             p2_6, p2_7, p2_8, p2_9, p2_10,
             ncol=2, nrow =5, layout_matrix=cbind(c(1,2,3,5,4),
                                                  c(6,7,8,10,9)))
xyMin=0.005
xyMax=0.995
xyOneHalf=0.5
xB = c(xyMin, xyMax, xyMin)
yV = c(xyOneHalf,xyOneHalf, xyOneHalf)
grid.polygon(yV,xB,gp=gpar(fill="transparent",lex=2))
#700x800
```

Perform correlation analyses for the fig1 data
```
p2_1_reg1 <- cor.test(combo_simul_eval_df$abl[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$robinson))],
    combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$robinson))],
    method="spearman")
p2_1_reg1$estimate
p2_1_reg1$p.value
p2_2_reg1 <- cor.test(combo_simul_eval_df$loclen[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_2_reg1$estimate
p2_2_reg1$p.value
p2_3_reg1 <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_3_reg1$estimate
p2_3_reg1$p.value
p2_4_reg1 <- cor.test(combo_simul_eval_df$prop_contamination[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_4_reg1$estimate
p2_4_reg1$p.value
p2_5_reg1 <- cor.test(combo_simul_eval_df$prop_paralogy[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$robinson))],
                      combo_simul_eval_df$robinson[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$robinson))],
                      method="spearman")
p2_5_reg1$estimate
p2_5_reg1$p.value
p2_6_reg1 <- cor.test(combo_simul_eval_df$abl[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$abl) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_6_reg1$estimate
p2_6_reg1$p.value
p2_7_reg1 <- cor.test(combo_simul_eval_df$loclen[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_7_reg1$estimate
p2_7_reg1$p.value
p2_7_reg1a <- cor.test(combo_simul_eval_df$loclen[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson)) & combo_simul_eval_df$prop_paralogy == 0],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$loclen) | is.na(combo_simul_eval_df$wrobinson)) & combo_simul_eval_df$prop_paralogy == 0],
                      method="spearman")
p2_7_reg1a$estimate
p2_7_reg1a$p.value
p2_8_reg1 <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_8_reg1$estimate
p2_8_reg1$p.value
p2_8_reg1a <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy == 0],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy == 0],
                      method="spearman")
p2_8_reg1a$estimate
p2_8_reg1a$p.value
p2_8_reg1b <- cor.test(combo_simul_eval_df$lambdaPS[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy > 0],
                       combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$lambdaPS) | is.na(combo_simul_eval_df$wrobinson))  & combo_simul_eval_df$prop_paralogy > 0],
                       method="spearman")
p2_8_reg1b$estimate
p2_8_reg1b$p.value
p2_9_reg1 <- cor.test(combo_simul_eval_df$prop_contamination[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$prop_contamination) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_9_reg1$estimate
p2_9_reg1$p.value
p2_10_reg1 <- cor.test(combo_simul_eval_df$prop_paralogy[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$wrobinson))],
                      combo_simul_eval_df$wrobinson[!(is.na(combo_simul_eval_df$prop_paralogy) | is.na(combo_simul_eval_df$wrobinson))],
                      method="spearman")
p2_10_reg1$estimate
p2_10_reg1$p.value
```

Prepare the data for Fig 2 (takes several hours...)
```
allbranchdfbrl <- tibble()
logbreaks <- seq(min(log(branchdata$brlen)), max(log(branchdata$brlen)), length.out = 10)
allbranchdfbrd <- tibble()
depthbreaks <- c(0, 0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1)
for (f in 1:20) {
  dsname <- ds_name_vector[f]
  t0 <- read.tree(paste0(ds_path_vector[f], "/1/s_tree.trees"))
  t0$edge.length <- t0$edge.length/max(nodeHeights(t0)[,2])*1.0
  t1l <- read.tree(paste0(ds_path_vector[f], "/inferred_gene_trees_Train.tre"))
  t1n <- readLines(paste0(ds_path_vector[f], "/inferred_gene_trees_Train.txt"))
  for (t1i in 1:length(t1n)){
    locname <- t1n[t1i]
    locRFsim <- combo_simul_eval_df$robinson[combo_simul_eval_df$loci == paste0(dsname, "_", locname)]
    locwRFsim <- combo_simul_eval_df$wrobinson[combo_simul_eval_df$loci == paste0(dsname, "_", locname)]
    if (locRFsim > 0.75) {
      RFsim <- "max"
    } else if (locRFsim < 0.25) {
      RFsim <- "min"
    } else {
      RFsim <- "medium"
    }
    if (locwRFsim > 0.75) {
      wRFsim <- "max"
    } else if (locwRFsim < 0.25) {
      wRFsim <- "min"
    } else {
      wRFsim <- "medium"
    }
    locbranchdf <- tibble(dsname=character(),
                          locname=character(),
                          brl=numeric(),
                          brd=numeric(),
                          alrt=numeric(),
                          ufboot=numeric())
    t1 <- t1l[[t1i]]
    for (branch in 1:length(t0$edge.length)){
      brdata <- t0$edge[branch,]
      brdep = node.depth.edgelength(t0)[brdata[1]]/max(node.depth.edgelength(t0))
      brlen = t0$edge.length[branch]/max(node.depth.edgelength(t0))
      descN <- t0$edge[branch,2]
      if (descN>length(t0$tip.label)) {
        descN2 <- t0$edge[which(t0$edge[,1] == descN),2]
        tgroupD1 <- t0$tip.label[unlist(Descendants(t0, descN2[1], type="tips"))]
        tgroupD2 <- t0$tip.label[unlist(Descendants(t0, descN2[2], type="tips"))]
        ancN <- t0$edge[branch,1]
        ancNd <- t0$edge[which(t0$edge[,1] == ancN),2]
        ancNd <- ancNd[ancNd != descN]
        if (length(ancNd) > 1) {
          ancNd1 <- ancNd[1]
          ancNd2 <- ancNd[2]
          tgroupA1 <- t0$tip.label[unlist(Descendants(t0, ancNd1, type="tips"))]
          tgroupA2 <- t0$tip.label[unlist(Descendants(t0, ancNd2, type="tips"))]
        } else {
          ancNd1 <- ancNd
          tgroupA1 <- t0$tip.label[unlist(Descendants(t0, ancNd1, type="tips"))]
          ancNd2 <- "othertips"
          tgroupA2 <- t0$tip.label[!(t0$tip.label %in% c(tgroupD1, tgroupD2, tgroupA1))]
        }
        tgroupD1a <- tgroupD1[tgroupD1 %in% t1$tip.label]
        tgroupD2a <- tgroupD2[tgroupD2 %in% t1$tip.label]
        tgroupA1a <- tgroupA1[tgroupA1 %in% t1$tip.label]
        tgroupA2a <- tgroupA2[tgroupA2 %in% t1$tip.label]
        if (length(tgroupD1a) > 0 &
            length(tgroupD2a) > 0 &
            length(tgroupA1a) > 0 &
            length(tgroupA2a) > 0) {
          if (is.monophyletic(t1,tgroupD1a) &
              is.monophyletic(t1,tgroupD2a) &
              is.monophyletic(t1,tgroupA1a) &
              is.monophyletic(t1,tgroupA2a)) {
            sisters <- numeric()
            mrcaD1 <- getMRCA(t1,tgroupD1a)
            if (is.null(mrcaD1)){
              mrcaD1 <- which(t1$tip.label == tgroupD1a)
            }
            mrcaD2 <- getMRCA(t1,tgroupD2a)
            if (is.null(mrcaD2)){
              mrcaD2 <- which(t1$tip.label == tgroupD2a)
            }
            mrcaA1 <- getMRCA(t1,tgroupA1a)
            if (is.null(mrcaA1)){
              mrcaA1 <- which(t1$tip.label == tgroupA1a)
            }
            mrcaA2 <- getMRCA(t1,tgroupA2a)
            if (is.null(mrcaA2)){
              mrcaA2 <- which(t1$tip.label == tgroupA2a)
            }
            
            if (mrcaD1 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1] && Siblings(t1, mrcaD1, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaD1, type="parent"))
            }
            if ((mrcaD2 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1]) && Siblings(t1, mrcaD2, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaD2, type="parent"))
            }
            if ((mrcaA1 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1]) && Siblings(t1, mrcaA1, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaA1, type="parent"))
            }
            if ((mrcaA2 != t1$edge[which(!(t1$edge[,1] %in% t1$edge[,2]))][1]) &&  Siblings(t1, mrcaA2, include.self = FALSE) %in% c(mrcaD1,mrcaD2,mrcaA1,mrcaA2)) {
              sisters <- c(sisters, Ancestors(t1, mrcaA2, type="parent"))
            }
            sisters <- unique(sisters)
            if (length(sisters) == 1) {
              corresponding_branch <- which(t1$edge[,2] == sisters)
              support <- as.numeric(unlist(strsplit(t1$node.label[t1$edge[corresponding_branch,2]-length(t1$tip.label)], "/")))
              locbranchdf <- add_row(locbranchdf, dsname=dsname, locname=locname, brl=brlen, brd=brdep,alrt=support[1], ufboot=support[2])
            }
          } else {
            locbranchdf <- add_row(locbranchdf, dsname=dsname, locname=locname, brl=brlen, brd=brdep,alrt=-1, ufboot=-1)
          }
        }
      }
    }
    locbranchdfbrd <- locbranchdf %>%
                        mutate( brdbin=cut(brd, breaks=depthbreaks,include.lowest = T)) %>%
                        group_by(dsname, locname, brdbin) %>%
                        dplyr::summarise(meanalrt = mean(alrt[alrt>-1]),
                                         meanufboot = mean(ufboot[ufboot>-1]),
                                         monophyProp = sum(alrt>-1)/length(alrt),
                                         .groups = "keep")
    locbranchdfbrd <- add_column(locbranchdfbrd, RFsim=RFsim, wRFsim=wRFsim)
    locbranchdfbrl <- locbranchdf %>%
                        mutate( brlbin=cut(log(brl), breaks = logbreaks,include.lowest = T)) %>%
                        group_by(dsname, locname, brlbin) %>%
                        dplyr::summarise(meanalrt = mean(alrt[alrt>-1]),
                                  meanufboot = mean(ufboot[ufboot>-1]),
                                  monophyProp = sum(alrt>-1)/length(alrt),
                                  .groups = "keep")
    locbranchdfbrl <- add_column(locbranchdfbrl, RFsim=RFsim, wRFsim=wRFsim)
    allbranchdfbrd <- rbind(allbranchdfbrd, locbranchdfbrd)
    allbranchdfbrl <- rbind(allbranchdfbrl, locbranchdfbrl)
  }
}
```

Prepare and plot Fig 2
```
p4_1 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_bar() + 
  scale_y_continuous(breaks=c(0, 20000)) +
  theme_bw() + 
  xlab("Branch length log bin") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))
p4_2 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  ylab("SH-aLRT, mean") +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_text(hjust = -0.8),
        legend.position = "none")
p4_3 <- ggplot(allbranchdfbrl, aes(x=brlbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_4 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  ylab("UFBoot, mean") +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_text(hjust = -1.5),
        legend.position = "none")
p4_5 <- ggplot(allbranchdfbrl, aes(x=brlbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_6 <- ggplot(allbranchdfbrl, aes(x=brlbin)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  ylab("Correct nodes, prop.") +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_text(hjust = -0.5),
        legend.position = "none")
p4_7 <- ggplot(allbranchdfbrl, aes(x=brlbin, fill=RFsim)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "top") +
  scale_fill_discrete(labels=c('high', 'medium', 'low'))
p4_8 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_bar() +
  scale_y_continuous(breaks=c(0, 20000)) +
  theme_bw() +
  xlab("Node height bin") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1),
        axis.title.y = element_blank())
p4_9 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_10 <- ggplot(allbranchdfbrd, aes(x=brdbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanalrt)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_11 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_12 <- ggplot(allbranchdfbrd, aes(x=brdbin, fill=RFsim)) +
  geom_boxplot(aes(y=meanufboot)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_13 <- ggplot(allbranchdfbrd, aes(x=brdbin)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none")
p4_14 <- ggplot(allbranchdfbrd, aes(x=brdbin, fill=RFsim)) +
  geom_boxplot(aes(y=monophyProp)) +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "top") +
  scale_fill_discrete(labels=c('high', 'medium', 'low'))

plot_grid(
  p4_7, p4_6, p4_5, p4_4, p4_3, p4_2, p4_1,
  p4_14, p4_13, p4_12, p4_11, p4_10, p4_9, p4_8,
  align = 'v',
  ncol = 2,
  nrow=7,
  byrow = F,
  rel_heights = c(1.75,1,1,1,1,1,2),
  rel_widths = c(1,1)
)
#700x800
```

Perform stats analysis on the data for Fig 2
```

# stats on branch length
library(rstatix)
statsbranchdfbrl <- as.data.frame(allbranchdfbrl[,c(3:8)])
#all bins combined
print(wilcox_test(data=statsbranchdfbrl, meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrl, meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrl, monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
#per bin tests
for (l in levels(statsbranchdfbrl$brlbin)) {
  print (l)
  print("meanalrt vs RF")
  print(wilcox_test(data=statsbranchdfbrl[statsbranchdfbrl$brlbin == l,], meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("meanufboot vs RF")
  print(wilcox_test(data=statsbranchdfbrl[statsbranchdfbrl$brlbin == l,], meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("monophyProp vs RF")
  print(wilcox_test(data=statsbranchdfbrl[statsbranchdfbrl$brlbin == l,], monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
}

# stats on node depth
statsbranchdfbrd <- as.data.frame(allbranchdfbrd[,c(3:8)])
#all bins combined
print(wilcox_test(data=statsbranchdfbrd, meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrd, meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
print(wilcox_test(data=statsbranchdfbrd, monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
#per bin tests
for (l in levels(statsbranchdfbrd$brdbin)) {
  print (l)
  print("meanalrt vs RF")
  print(wilcox_test(data=statsbranchdfbrd[statsbranchdfbrd$brdbin == l,], meanalrt~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("meanufboot vs RF")
  print(wilcox_test(data=statsbranchdfbrd[statsbranchdfbrd$brdbin == l,], meanufboot~RFsim, paired = F, p.adjust.method = "bonferroni"))
  print("monophyProp vs RF")
  print(wilcox_test(data=statsbranchdfbrd[statsbranchdfbrd$brdbin == l,], monophyProp~RFsim, paired = F, p.adjust.method = "bonferroni"))
}
```

## Model training

### Prepare (combine) dataset tables

Before the model is trained, feature assessment tables across all simulation datasets are merged together and subsetted based on the type of model training (for ex, wRF column is excluded when training using RF as the proxy for phylogenetic utility). 

First, prepare a file with a list of files to consider:
```
path_to_simulations/empirical/fong/ML_train.txt
path_to_simulations/empirical/wickett/ML_train.txt
...
etc
```

Then create final files for model training and locus utility prediction, excluding certain columns as follows:
```
#RF similarity
#train Y
python3 ~/tools/PML/model_training/prep_train_table.py train_list.txt 2 3
#all woY
python3 ~/tools/PML/model_training/prep_train_table.py all_list.txt 1 2 3

#wRF similarity
#train Y
python3 ~/tools/PML/model_training/prep_train_table.py train_list.txt 1 3
#all woY
python3 ~/tools/PML/model_training/prep_train_table.py all_list.txt 1 2 3
```


### Run model training

For each of the Y variables, train the model:
```
python ~/tools/PML/model_training/train_random_forest.py RFtrain_tab.tsv
```
and / or:
```
python ~/tools/PML/model_training/train_random_forest.py wRFtrain_tab.tsv
```

Each time the trained model will be saved in a file `model_file.bin` (can overwrite previous results)


## Evaluate model training

### Accuracy and feature importances

Read model feature importances data (in this case parsed from the logs)
```
impTabRF <- data.frame(feature=c("average_support",
                                 "treeness",
                                 "tree_rate",
                                 "tree_rate_var",
                                 "base_composition_variance",
                                 "saturation_slope",
                                 "saturation_rsq",
                                 "occupancy",
                                 "alignment_length",
                                 "percent_missing",
                                 "percent_variable",
                                 "phyloinf"),
                       importance=c(9.73702538e-01, 1.66086255e-02, 1.32360382e-02, 6.06317355e-02,
                                    9.81859885e-04, 1.62718732e-02, 2.70854680e-02, 4.35649527e-03,
                                    2.92660164e-04, 3.57253274e-04, 1.33417915e-03, 4.46158657e-02),
                       impstd=c(0.01832637, 0.00130111, 0.0018444 , 0.00421057, 0.00056582,
                                0.00150674, 0.00247988, 0.00039014, 0.00062477, 0.00070478,
                                0.00052206, 0.0018445))
impTabwRF <- data.frame(feature=c("average_support",
                                  "treeness",
                                  "tree_rate",
                                  "tree_rate_var",
                                  "base_composition_variance",
                                  "saturation_slope",
                                  "saturation_rsq",
                                  "occupancy",
                                  "alignment_length",
                                  "percent_missing",
                                  "percent_variable",
                                  "phyloinf"),
                        importance=c(0.17407202, 0.18559437, 0.77870074, 1.24062328, 0.00132746,
                                     0.0246681 , 0.08197561, 0.00935731, 0.00262903, 0.00178277,
                                     0.00524842, 0.03205178),
                        impstd=c(0.00371503, 0.00919996, 0.01253998, 0.03352566, 0.000293  ,
                                 0.00156901, 0.00461332, 0.00096884, 0.0004419 , 0.0005136 ,
                                 0.00057207, 0.00229909))
p3_1 <- ggplot(impTabRF, aes(y=feature)) +
  geom_barh(aes(x=importance), stat="identity") + 
  geom_errorbarh(aes(xmin=importance-impstd, xmax=importance+impstd),stat="identity") +
  theme_bw() +
  xlab("Permutation importance (mean)")

p3_3 <- ggplot(impTabwRF, aes(y=feature)) +
  geom_barh(aes(x=importance), stat="identity") + 
  geom_errorbarh(aes(xmin=importance-impstd, xmax=importance+impstd),stat="identity") +
  theme_bw() +
  xlab("Permutation importance (mean)")
```

Read in the training and testing accuracy data and plot
```
#read RF data
predictedRF_df <- read.csv("model_training/RF/all/ML_predicted.csv", header = T)
combo_simul_eval_df_predRF <- merge(combo_simul_eval_df, predictedRF_df, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predRF$MLset <- factor(combo_simul_eval_df_predRF$MLset,
                                           levels = c("train", "test"))
regressionRF=function(df){
  #setting the regression function. 
  reg_fun<-lm(formula=df$RFsimilarity~df$robinson) #regression function
  #getting the slope, intercept, R square and adjusted R squared of 
  #the regression function (with 3 decimals).
  slope<-round(coef(reg_fun)[2],3)  
  intercept<-round(coef(reg_fun)[1],3) 
  R2<-round(as.numeric(summary(reg_fun)[8]),3)
  R2.Adj<-round(as.numeric(summary(reg_fun)[9]),3)
  c(slope,intercept,R2,R2.Adj)
}
#plot RF data
regressions_RF_data<-ddply(combo_simul_eval_df_predRF,"MLset",regressionRF)
colnames(regressions_RF_data)<-c ("MLset","slope","intercept","R2","R2.Adj")
p3_2 <- ggplot(combo_simul_eval_df_predRF,
               aes(x=robinson, y=RFsimilarity)) +
          geom_point() +
          geom_smooth(method = "lm") + 
          geom_label(data=regressions_RF_data, inherit.aes=FALSE, parse = T,
                     aes(x = 0.25, y = 0.7,
                         label=paste("R^2:",R2)
                     )) +
          theme_bw() +
          facet_wrap(.~MLset) +
          ylab("predicted RF similarity") +
          xlab("True RF similarity")

#read wRF data
predictedwRF_df <- read.csv("model_training/wRF/all/ML_predicted.csv", header = T)
combo_simul_eval_df_predwRF <- merge(combo_simul_eval_df, predictedwRF_df, by.x = "loci", by.y = "locname")
combo_simul_eval_df_predwRF$MLset <- factor(combo_simul_eval_df_predwRF$MLset,
                                            levels = c("train", "test"))
regressionwRF=function(df){
  #setting the regression function. 
  reg_fun<-lm(formula=df$RFsimilarity~df$wrobinson) #regression function
  #getting the slope, intercept, R square and adjusted R squared of 
  #the regression function (with 3 decimals).
  slope<-round(coef(reg_fun)[2],3)  
  intercept<-round(coef(reg_fun)[1],3) 
  R2<-round(as.numeric(summary(reg_fun)[8]),3)
  R2.Adj<-round(as.numeric(summary(reg_fun)[9]),3)
  c(slope,intercept,R2,R2.Adj)
}
#plot wRF data
regressions_wRF_data<-ddply(combo_simul_eval_df_predwRF,"MLset",regressionwRF)
colnames(regressions_wRF_data)<-c ("MLset","slope","intercept","R2","R2.Adj")
p3_4 <- ggplot(combo_simul_eval_df_predwRF,
               aes(x=wrobinson, y=RFsimilarity)) +
  geom_point() +
  geom_smooth(method = "lm") + 
  geom_label(data=regressions_wRF_data, inherit.aes=FALSE, parse = T,
             aes(x = 0.25, y = 0.7,
                 label=paste("R^2:",R2)
             )) +
  theme_bw() +
  facet_wrap(.~MLset) +
  ylab("predicted wRF similarity") +
  xlab("True wRF similarity")
p3_4

#plot final image
grid.arrange(p3_1, p3_2, p3_3, p3_4,
             ncol=2, nrow =2)
#400x800
```

### Interaction btw features

First, assess the interactions in each model. Navigate to the folder with the model, create a folder for interaction results and change into it:

```
#navigate to the folder with the model data
mkdir interactions
cd interactions
python ~/tools/PML/model_training/investigate_interaction.py -i ../wRFall_tab.tsv -m ../model_file.bin
```

RF model: Construct the feature interaction bar plots, join with the python generated figures and output the final image
```
#H-statistic plots - RF
#Christoph Molnar discusses in his interpretable ML book
#blog.macuyiko.com/
hstat1stdf <- read.csv("model_training/RF/all/interaction/first_order_H_vals.csv")
colnames(hstat1stdf)[2] <- "hvals"
hstat2nddf <- read.csv("model_training/RF/all/interaction/second_order_H_vals.csv")
colnames(hstat2nddf) <- c("combinations", "hvals")
p4_1 <- ggplot(hstat1stdf) +
  geom_barh(aes(x=hvals, y=features), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11)) +
  xlab("First-order H-statistic")

p4_2 <- ggplot(hstat2nddf[1:10,]) +
  geom_barh(aes(x=hvals, y=reorder(combinations, hvals)), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11),
        axis.title.x = element_text(size=10)) +
  xlab("Second-order H-statistic for top 10 combinations") +
  ylab("combinations")

#### INTERACTION PLOTS from the python - adjust paths and names accordingly
library(rsvg)
library(grImport2)

#RF int1
rsvg_svg("model_training/RF/all/interaction/tree_rate_var x phyloinf.svg", "p4_3pre.svg")
p4_3pre <- readPicture("p4_3pre.svg")
p4_3 <- grobify(p4_3pre)
#RF int2
rsvg_svg("model_training/RF/all/interaction/tree_rate x alignment_length.svg", "p4_4pre.svg")
p4_4pre <- readPicture("p4_4pre.svg")
p4_4 <- grobify(p4_4pre)
#RF int3
rsvg_svg("model_training/RF/all/interaction/tree_rate x tree_rate_var.svg", "p4_5pre.svg")
p4_5pre <- readPicture("p4_5pre.svg")
p4_5 <- grobify(p4_5pre)
#RF int4
rsvg_svg("model_training/RF/all/interaction/alignment_length x percent_missing.svg", "p4_6pre.svg")
p4_6pre <- readPicture("p4_6pre.svg")
p4_6 <- grImport2::grobify(p4_6pre)

grid.arrange(p4_1, p4_2, p4_3, p4_4, p4_5, p4_6,
            ncol=2, nrow =3, layout_matrix=rbind(c(1,1,2,2),
                                                 c(3,4,5,6)))
#1200x500
```

wRF model: similarly to the previous workflow, do the same for the wRF model interactions data:
```

hstat1stdf <- read.csv("model_training/wRF/all/interaction/first_order_H_vals.csv")
colnames(hstat1stdf)[2] <- "hvals"

hstat2nddf <- read.csv("model_training/wRF/all/interaction/second_order_H_vals.csv")
colnames(hstat2nddf) <- c("combinations", "hvals")
p5_1 <- ggplot(hstat1stdf) +
  geom_barh(aes(x=hvals, y=features), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11)) +
  xlab("First-order H-statistic")

p5_2 <- ggplot(hstat2nddf[1:10,]) +
  geom_barh(aes(x=hvals, y=reorder(combinations, hvals)), stat="identity") + 
  theme_bw() +
  theme(axis.text.y=element_text(size=11),
        axis.title.x = element_text(size=10)) +
  xlab("Second-order H-statistic for top 10 combinations") +
  ylab("combinations")


#### INTERACTION PLOTS from the python - adjust paths and names accordingly
#wRF int1
rsvg_svg("model_training/wRF/all/interaction/tree_rate x tree_rate_var.svg", "p5_3pre.svg")
p5_3pre <- readPicture("p5_3pre.svg")
p5_3 <- grobify(p5_3pre)
#wRF int2
rsvg_svg("model_training/wRF/all/interaction/average_support x tree_rate_var.svg", "p5_4pre.svg")
p5_4pre <- readPicture("p5_4pre.svg")
p5_4 <- grobify(p5_4pre)
#wRF int3
rsvg_svg("model_training/wRF/all/interaction/treeness x saturation_slope.svg", "p5_5pre.svg")
p5_5pre <- readPicture("p5_5pre.svg")
p5_5 <- grobify(p5_5pre)
#wRF int4
rsvg_svg("model_training/wRF/all/interaction/tree_rate_var x saturation_rsq.svg", "p5_6pre.svg")
p5_6pre <- readPicture("p5_6pre.svg")
p5_6 <- grImport2::grobify(p5_6pre)

grid.arrange(p5_1, p5_2, p5_3, p5_4, p5_5, p5_6,
             ncol=2, nrow =3, layout_matrix=rbind(c(1,1,2,2),
                                                  c(3,4,5,6)))
#1200x500

```

Additionally, for the supplements, marginalize over the extremes of one of the properties (high and low rate, high or 0 paralogy) and plot importances depending on the model. This provides insight into how differently trained models detect same locus properties.
```
#predicted importance vs features - top abl, bottom abl, top paralog, 0 paralog
#rate
colnames(combo_simul_eval_df_predRF)
length(combo_simul_eval_df_predRF$abl[combo_simul_eval_df_predRF$abl<(-19.7) & combo_simul_eval_df_predRF$paralog_cont==0 & combo_simul_eval_df_predRF$cont_pair_cont==0])
length(combo_simul_eval_df_predRF$abl[combo_simul_eval_df_predRF$abl>(-18) & combo_simul_eval_df_predRF$paralog_cont==0 & combo_simul_eval_df_predRF$cont_pair_cont==0])
highlowrateRFdf <- melt(combo_simul_eval_df_predRF[(combo_simul_eval_df_predRF$abl<(-19.7) |
                                                   combo_simul_eval_df_predRF$abl>(-18)) & 
                                                     combo_simul_eval_df_predRF$paralog_cont==0 & 
                                                     combo_simul_eval_df_predRF$cont_pair_cont==0,
                                                 c(1:2,55:66)],
                      id=c("loci", "abl"))
levels(highlowrateRFdf$variable) <- gsub("\\.y","", levels(highlowrateRFdf$variable))
highlowrateRFdf$rate <- "high (>ln(-18))"
highlowrateRFdf$rate[highlowrateRFdf$abl<(-19.7)] <- "low (<ln(-19.7))"
p6_1 <- ggplot(highlowrateRFdf) +
  geom_boxploth(aes(x=value, y=variable,fill= rate),outlier.shape = NA) +
  theme_bw() +
  ylab("features") +
  xlab("importances") +
  ggtitle("RF model: high vs low rate")

hist(combo_simul_eval_df_predRF$prop_paralogy)

highlowratewRFdf <- melt(combo_simul_eval_df_predwRF[(combo_simul_eval_df_predwRF$abl<(-19.7) |
                                                      combo_simul_eval_df_predwRF$abl>(-18)) & 
                                                     combo_simul_eval_df_predwRF$paralog_cont==0 & 
                                                     combo_simul_eval_df_predwRF$cont_pair_cont==0,
                                                   c(1:2,55:66)],
                        id=c("loci", "abl"))
levels(highlowratewRFdf$variable) <- gsub("\\.y","", levels(highlowratewRFdf$variable))
highlowratewRFdf$rate <- "high (>ln(-18))"
highlowratewRFdf$rate[highlowratewRFdf$abl<(-19.7)] <- "low (<ln(-19.7))"
p6_3 <- ggplot(highlowratewRFdf) +
  geom_boxploth(aes(x=value, y=variable,fill= rate),outlier.shape = NA) +
  theme_bw() +
  ylab("features") +
  xlab("importances") +
  ggtitle("wRF model: high vs low rate")


# highlowparalogRFdf <- melt(rbind(combo_simul_eval_df_predRF[combo_simul_eval_df_predRF$paralog_cont>4,c(1,16,53:64)],
#                                  combo_simul_eval_df_predRF[combo_simul_eval_df_predRF$paralog_cont==0,c(1,16,53:64)][1:1000,]),
#                            id=c("loci", "paralog_cont"))
length(which(combo_simul_eval_df_predRF$prop_paralogy>0.04 &
               (combo_simul_eval_df_predRF$abl >19 | combo_simul_eval_df_predRF$abl <18) &
               combo_simul_eval_df_predRF$cont_pair_cont==0))
highlowparalogRFdf <- melt(rbind(combo_simul_eval_df_predRF[combo_simul_eval_df_predRF$prop_paralogy>0.04 &
                                                              (combo_simul_eval_df_predRF$abl >19 | combo_simul_eval_df_predRF$abl <18) &
                                                              combo_simul_eval_df_predRF$cont_pair_cont==0,c(1,28,55:66)],
                                 combo_simul_eval_df_predRF[combo_simul_eval_df_predRF$paralog_cont==0 &
                                                              (combo_simul_eval_df_predRF$abl >19 | combo_simul_eval_df_predRF$abl <18) &
                                                              combo_simul_eval_df_predRF$cont_pair_cont==0,c(1,28,55:66)][1:1000,]),
                           id=c("loci", "prop_paralogy"))
length(combo_simul_eval_df_predRF[combo_simul_eval_df_predRF$prop_paralogy>0.04,1])
levels(highlowparalogRFdf$variable) <- gsub("\\.y","", levels(highlowparalogRFdf$variable))
highlowparalogRFdf$paralogy <- "low (0%)"
highlowparalogRFdf$paralogy[highlowparalogRFdf$prop_paralogy>0] <- "high (>4%)"

p6_2 <- ggplot(highlowparalogRFdf) +
  geom_boxploth(aes(x=value, y=variable,fill= paralogy),outlier.shape = NA) +
  theme_bw() +
  theme(axis.title.y = element_blank()) +
  xlab("importances") +
  ggtitle("RF model: high vs low paralogy")

highlowparalogwRFdf <- melt(rbind(combo_simul_eval_df_predwRF[combo_simul_eval_df_predwRF$prop_paralogy>0.04 &
                                                              (combo_simul_eval_df_predwRF$abl >19 | combo_simul_eval_df_predwRF$abl <18) &
                                                              combo_simul_eval_df_predwRF$cont_pair_cont==0,c(1,28,55:66)],
                                 combo_simul_eval_df_predwRF[combo_simul_eval_df_predwRF$paralog_cont==0 &
                                                              (combo_simul_eval_df_predwRF$abl >19 | combo_simul_eval_df_predwRF$abl <18) &
                                                              combo_simul_eval_df_predwRF$cont_pair_cont==0,c(1,28,55:66)][1:1000,]),
                           id=c("loci", "prop_paralogy"))

levels(highlowparalogwRFdf$variable) <- gsub("\\.y","", levels(highlowparalogwRFdf$variable))
highlowparalogwRFdf$paralogy <- "low (0%)"
highlowparalogwRFdf$paralogy[highlowparalogwRFdf$prop_paralogy>0] <- "high (>4%)"

p6_4 <- ggplot(highlowparalogwRFdf) +
  geom_boxploth(aes(x=value, y=variable,fill= paralogy),outlier.shape = NA) +
  theme_bw() +
  theme(axis.title.y = element_blank()) +
  xlab("importances") +
  ggtitle("wRF model: high vs low paralogy")

grid.arrange(p6_1, p6_2, p6_3, p6_4, ncol=2, nrow =2, widths=c(0.52,0.48))
#945x647
```

### Impact of subsampling

```
Scripts for fig 7
```


## Evaluate empirical datasets

### Assess features

### Predict utility

### Subsetting experiments

Done
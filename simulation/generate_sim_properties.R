library(ape)
library(geiger)
library(MultiRNG)
library(EnvStats)
library(extraDistr)
#settings
nloci <- 2000
args <- commandArgs(trailingOnly=TRUE)
sptree <- read.tree(args[1])
Ne <- as.numeric(args[2])
random_seed <- as.numeric(args[3])
#write.nexus(sptree, file="sptree.nex", translate = F)
write("#NEXUS", file="sptree.nex")
write("begin trees;", file="sptree.nex", append=T)
write(paste0("\ttree tree_1 = [&R] ", write.tree(sptree,file="")), file="sptree.nex", append=T)
write("end;", file="sptree.nex", append=T)
ntaxa <- length(sptree$tip.label)
df <- data.frame(loci=paste0("loc_",as.character(1:nloci)))
set.seed(random_seed)

#average branch length - rate
abl <- round(runif(nloci,min=-17,max=-13),3)
df <- cbind(df, abl)

#variance in branch length - variance in rate - heterotachy
vbl <- round(runif(nloci,min=0.5,max=5.5),3)
df <- cbind(df, vbl)

#CDS or NOT
proteinCoding <- sample(c(TRUE,FALSE), nloci, TRUE)
df <- cbind(df, proteinCoding)

modeldf <- data.frame(modelType=character(),baseFreq=list(),paramVector=list())
for (f in 1:nloci) {
	if (proteinCoding[f] == TRUE) {
		modelType <- "M2"
		basefreqs <- NA #rep(0.015625, 64)
		kappa <- round(rlnormTrunc(1,log(4), log(2.5),max=14),3)
		pInv <- round(runif(1,min=0,max=0.25),3)
		pNeutral <- round(runif(1,min=0,max=0.75),3)
		omegaInv <- 0 #no change
		omegaNeut <- 1 #syn=nonsyn
		omegaSelect <- round(runif(1,min=0,max=3),3)
		paramvector <- c(kappa, pInv, pNeutral, omegaInv, omegaNeut, omegaSelect)
		paramvector[7] <- round(runif(1,min=1.5,max=2),3) #indel model
		paramvector[8] <- round(runif(1,min=0.001,max=0.002),5) #indel rate
	} else {
		#substitution model
		modelType <- sample(c("GTR", "SYM", "TVM", "TVMef", "TIM",
							"TIMef", "K81uf", "K81", "TrN", "TrNef",
							"HKY", "K80", "F81", "JC"),1)

		#substitution model base freqs
		if (modelType %in% c("GTR", "TVM", "TIM", "K81uf", "TrN", "HKY", "F81")) {
			#T C A G
			basefreqs <- round(draw.dirichlet(1,4,c(10,10,10,10),1)[1,],3)
			basefreqs[4] <- 1-sum(basefreqs[1:3])
		} else {
			basefreqs = NA
		}

		#substitution model exchangeabilities (1-6) and RVAS (7-9)
		paramvector <- rep(NA,9)
		 #               a = TC;   b = TA;  c = TG;  
			# a1 = CT;             d = CA;  e = CG;  
			# b1 = AT;  d1 = AC;            f = AG;  
			# c1 = GT;  e1 = GC;  f1 = GA; 
		#set exA - TC
		if (modelType == "K80" | modelType == "HKY" | modelType == "TrN" | modelType == "TrNef" |
			modelType == "TIM" | modelType == "TIMef" | modelType == "GTR" | modelType == "SYM") {
			# paramvector[1] = runif(1,min=0.1,max=2.0)
			paramvector[1] = round(rlnormTrunc(1,log(4), log(2.5),max=16),3)
		}
		#set exB and exC - TA and TG
		if (modelType == "K81" | modelType == "K81uf" | modelType == "TIM" | modelType == "TIMef" | 
			modelType == "TVM" | modelType == "TVMef" | modelType == "GTR" | modelType == "SYM") {
			# paramvector[2] = runif(1,min=0.1,max=2.0)
			# paramvector[3] = runif(1,min=0.1,max=2.0)
			paramvector[2] = round(rlnormTrunc(1,log(1.25), log(2.5),max=3.5),3)
			paramvector[3] = round(rlnormTrunc(1,log(3), log(2.5),max=9),3)
		}
		#set exD and exE - CA and CG
		if (modelType == "TVM" | modelType == "TVMef" | modelType == "GTR" | modelType == "SYM") {
			# paramvector[4] = runif(1,min=0.1,max=2.0)
			# paramvector[5] = runif(1,min=0.1,max=2.0)
			paramvector[4] = round(rlnormTrunc(1,log(1), log(2.5),max=2.5),3)
			paramvector[5] = round(rlnormTrunc(1,log(0.8), log(2.5),max=2),3)
		}
		#set exF - AG
		if (modelType == "TrN" | modelType == "TrNef") {
			# paramvector[6] = runif(1,min=0.1,max=2.0)
			paramvector[6] = round(rlnormTrunc(1,log(3), log(2.5),max=9),3)
		}
		#pinv
		paramvector[7] <- round(runif(1,min=0,max=0.25),5)
		#alpha
		paramvector[8] <- round(rlnormTrunc(1,log(0.3), log(2.5),max=1.4),5)
		#ngamcat, continuous, none, or 2-10 discrete
		paramvector[9] <- sample(0:10,1)
		if (paramvector[9] == 1) {
			# if 1 category, set alpha to 0 to turn off RVAS
			paramvector[8] <- 0
		}
		#indel model
		paramvector[10] <- round(runif(1,min=1.5,max=2),3)
		#indel rate
		paramvector[11] <- round(runif(1,min=0.001,max=0.002),5)
	}
	rowdf <- data.frame(modelType=modelType,baseFreq=I(list(basefreqs)),paramVector=I(list(paramvector)))
	# print(rowdf)
	modeldf <- rbind(modeldf, rowdf)
}
df <- cbind(df, modeldf)

#locus length
loclen <- sample(200:1000,nloci, replace=T)
df <- cbind(df, loclen)

#proportion of phylogenetic signal on internal branches
lambdaPS <- round(runif(nloci,min=0.8,max=1.0),5)
df <- cbind(df, lambdaPS)

#amount of ILS - proportional to Ne
Ne <- rep(Ne, nloci)
df <- cbind(df, Ne)

#simphy seeds
seed1 <- sample(10000:99999,nloci, replace=F)
df <- cbind(df, seed1)

#indelible seeds
seed2 <- sample(10000:99999,nloci, replace=F)
df <- cbind(df, seed2)

#entirely missing taxa
ntaxa_missing <- sample(0:round(ntaxa/2),nloci, replace=T)
taxa_missing <- list()
remaining_taxa <- list()
for (f in ntaxa_missing){
	txm <- sample(c(1:ntaxa),f, replace=F)
	taxa_missing <- c(taxa_missing, list(txm))
	remaining_taxa <- c(remaining_taxa, list(setdiff(c(1:ntaxa), txm)))
}
df$remaining_taxa <- remaining_taxa
df$taxa_missing <- taxa_missing

#taxa with partially missing data
nremaining_taxa <- lapply(remaining_taxa, length )
taxa_missing_segments <- lapply(remaining_taxa, function(x) sample(x,round(length(x)/2)))
df$taxa_missing_segments <- taxa_missing_segments

#proportions of missing data per missing data taxon
missing_segments_prop <- lapply(taxa_missing_segments, function(x) round(runif(length(x),min=0.4,max=0.8),3))
df$missing_segments_prop <- missing_segments_prop
missing_segments_bias <- lapply(taxa_missing_segments, function(x) round(runif(length(x),min=0,max=1),2))
df$missing_segments_bias <- missing_segments_bias

#number of paralogs per gene
# zero-inflated poisson
paralog_cont <- rzip(nloci, unlist(nremaining_taxa)/10, 0.5)
df <- cbind(df, paralog_cont)
#taxa selected to be deep paralogs in each gene
paralog_taxa <- apply(df, 1, function(x) sample(x$remaining_taxa,x$paralog_cont) )
df$paralog_taxa <- paralog_taxa

#number of contaminant groups per gene
cont_pair_cont <- rzip(nloci, unlist(nremaining_taxa)/50, 0.5)
df <- cbind(df, cont_pair_cont)
#taxa selected to be contaminants in each gene
cont_pairs <- apply(df, 1, function(x) sample(x$remaining_taxa,x$cont_pair_cont*2) )
df$cont_pairs <- cont_pairs

# print (df)
df <- apply(df,2,as.character)
write.csv(df,"df.csv")
library(ape)
library(phytools)
library(phangorn)
library(adephylo)
library(seqinr)
library(PhyInformR)
library(rjson)
library(psych)
library(MESS)

args = commandArgs(trailingOnly=TRUE)
argsLen <- length(args)
alignment_folder_path <- args[1]
gene_tree_file_path <- args[2]
gene_name_file_path <- args[3]
pruned_species_tree_file_path <- args[4]
amas_table_path <- args[5]
rate_folder_path <- args[6]
output_name <- args[7]
if (argsLen == 8) {
	fastsp_table_path <- args[8]
}

gene_trees <- read.tree(gene_tree_file_path)
names(gene_trees) <- readLines(gene_name_file_path)

species_trees <- read.tree(pruned_species_tree_file_path)

amas_table <- read.table(amas_table_path, header=T, check.names = F)

taxon_list <- character()

nloci <- length(gene_trees)

average_support <- vector(length = nloci)
robinson <- vector(length = nloci)
wrobinson <- vector(length = nloci)
treeness <- vector(length = nloci)
tree_rate <- vector(length = nloci)
tree_rate_var <- vector(length = nloci)
base_composition_variance <- vector(length = nloci)
saturation_slope <- vector(length = nloci)
saturation_rsq <- vector(length = nloci)
number_of_taxa <- vector(length = nloci)
alignment_length <- vector(length = nloci)
percent_missing <- vector(length = nloci)
percent_variable <- vector(length = nloci)
phyloinf <- vector(length = nloci)
if (argsLen == 8) {
	fastsp_table <- read.csv(fastsp_table_path, header=F)
	alignmentSPscore <- vector(length = nloci)
}

for (f in 1:nloci) {
	locname <- names(gene_trees)[f]
	print (locname)
	geneTree <- gene_trees[[f]]
	for (tip in geneTree$tip.label) {
		if (!(tip %in% taxon_list)) {
			taxon_list <- c(taxon_list, tip)
		}
	}
	pruned_species_tree <- species_trees[[f]]
	alignment <- read.dna(paste0(alignment_folder_path, "/", locname), "fasta")

	if ("node.label" %in% names(geneTree)) {		
		#average bs
		ufboot <- sapply(strsplit(geneTree$node.label, "/"), function(x) x[2])
		average_support[f] <- mean(as.numeric(ufboot), na.rm = T)

		#RF/wRF
		if (argsLen == 8) {
			#Compute RF similarity
			robinson[f] <- 1 - suppressMessages(RF.dist(pruned_species_tree, geneTree, normalize = TRUE, check.labels = TRUE))
			#Rescale tree to length of 1
			geneTree1 <- geneTree
			geneTree1$edge.length <- geneTree1$edge.length/max(nodeHeights(geneTree1)[,2])*1.0
			#Compute wRF similarity on the rescaled tree
			wrobinson[f] <- 1 - suppressMessages(wRF.dist(pruned_species_tree, geneTree1, normalize = TRUE, check.labels = TRUE))			
			#Compute alignment similarity
			alignmentSPscore[f] <- fastsp_table$V2[fastsp_table$V1 == locname]
		}
	 
	    #tip branches
	   	tip_branches <- which(geneTree$edge[,2] %in% c(1:length(geneTree$tip.label)))
	    
	    #treeness
	    treeness[f] <- 1 - (sum(geneTree$edge.length[tip_branches])/sum(geneTree$edge.length))

	    #tree length
	    tree_length <- sum(geneTree$edge.length)

	    #tree based rate
	    tree_rate[f] <- tree_length/length(geneTree$tip.label)

	    #tree based rate variation
	    tree_rate_var[f] <- var(geneTree$edge.length)

	    #base_composition_variance
	    taxa_num <- length(alignment[,1])
	    base_freq_mx <- base.freq(alignment[1,])
	    for (t in 2:taxa_num){
	    	base_freq_mx <- rbind(base_freq_mx, base.freq(alignment[t,]))
	    }
	    base_composition_variance[f] <- sum(apply(base_freq_mx,2,var))


		#saturation
		p_mat <- dist.dna(alignment, model = "raw", pairwise.deletion = T)
		# make matrix of pairwise distances in branch lengths from the tree
		cophentr <- cophenetic(geneTree)  
		# store as matrix object
		mat_p_mat <- as.matrix(p_mat)
		# print(apply(mat_p_mat, 2, mean))
		# order p-distance matrix by names
		mat_p_mat <- mat_p_mat[order(row.names(mat_p_mat)),order(row.names(mat_p_mat))]
		mat_co <- as.matrix(cophentr)
		# order pairwise distances matrix by names
		mat_co <- mat_co[order(row.names(mat_co)),order(row.names(mat_co))]
		# get lower triangulars of both matrices
		branch_dist <- mat_co[lower.tri(mat_co)]
		p_dist <- mat_p_mat[lower.tri(mat_p_mat)]
		# perform simple linear regression
		regress <- lm(p_dist ~ branch_dist)
		# get slope
		saturation_slope[f] <- coef(regress)[2]
		# get r-squared
		saturation_rsq[f] <- summary(regress)$r.squared

		#number of taxa - for occupancy computation
		number_of_taxa[f] <- length(geneTree$tip.label)

		#amas subset
		amas_entry <- amas_table[amas_table$Alignment_name == locname,]

		#alignment_length
		alignment_length[f] <- amas_entry$Alignment_length

		#percent_missing
		percent_missing[f] <- amas_entry$Missing_percent

		# percent_variable
		percent_variable[f] <- amas_entry$Proportion_variable_sites

		rates_fname <- paste0(rate_folder_path, "/", locname, ".LEISR.json")
		if (file.exists(rates_fname)) {
			rates <- fromJSON(file = rates_fname)
			rates_per_site <- sapply(rates$MLE$content$`0`, function(x) x[1])
			
			#penalized PI
			as.matrix(rates_per_site)->rr
			fit1 <- data.frame(x1=numeric(),
		                   y1=numeric())
			for (t2a in seq(0,1,0.01)){
			  phyinf = PhyInformR:::site.summer(rr,t2a)
			  t2b <- data.frame(x1=t2a,
			                    y1=phyinf)
			  fit1 <- rbind(fit1, t2b)
			}
			#find peak in informativeness and penalize values at times older than the
			#peak by a factor proportional to their decay
			max1 = which(fit1$y1 == max(fit1$y1))[1]  # Take only the first max index because an error is caused if max1 is a vector (because multiple indices have the maximum value)
			inform_pen = fit1$y1
			if(max1 != length(fit1$y1)) {
			  for(j in (max1 + 1):length(fit1$y1)) {
			    inform_pen[j] = fit1$y1[j]*(fit1$y1[j]/fit1$y1[max1])
			  }
			}
			#auc
			phyloinf[f] <- auc(fit1$x1, inform_pen,type = "spline")
		} else {
			phyloinf[f] <- NA
		}
	} else {
		average_support[f] <- NA
		if (argsLen == 8) {
			robinson[f] <- NA
			wrobinson[f] <- NA
			alignmentSPscore[f] <- NA
		}
		treeness[f] <- NA
		tree_rate[f] <- NA
		tree_rate_var[f] <- NA
		base_composition_variance[f] <- NA
		saturation_slope[f] <- NA
		saturation_rsq[f] <- NA
		number_of_taxa[f] <- NA
		alignment_length[f] <- NA
		percent_missing[f] <- NA
		percent_variable[f] <- NA
		phyloinf[f] <- NA
	}
}

#rescale taxon number by the total number of taxa
#to obtain occupancy
occupancy <- number_of_taxa / length(taxon_list)

#gather gene properties
if (argsLen == 8) {
	variables <- data.frame(locname=names(gene_trees),
		robinson, wrobinson, alignmentSPscore,
		average_support, treeness, tree_rate, tree_rate_var,
		base_composition_variance, saturation_slope, saturation_rsq,
		occupancy, alignment_length, percent_missing, percent_variable, phyloinf)
} else {
	variables <- data.frame(locname=names(gene_trees),
		average_support, treeness, tree_rate, tree_rate_var,
		base_composition_variance, saturation_slope, saturation_rsq,
		occupancy, alignment_length, percent_missing, percent_variable, phyloinf)
}
write.table(variables, output_name, row.names = F, sep = '\t')

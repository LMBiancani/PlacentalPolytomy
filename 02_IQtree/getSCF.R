library (ape)
args = commandArgs(trailingOnly=TRUE)
argsLen <- length(args);
if (argsLen == 0){
  cat("Syntax: Rscript getSCF.R [path to .cf.branch] [path to .cf.stat] [path to tips list] [path to outgroup tips list] \n")
  cat("Example: Rscript getSCF.R test.cf.branch test.cf.stat tipsToAnalyse.txt outgroup.txt\n")
  quit()
}
reftree <- read.tree(args[1]) #tree
stattable <- read.table(args[2],header=TRUE, fill=TRUE) # from iqtree
filtertaxa <- readLines(args[3]) # focal tips
outtaxa <- readLines(args[4]) # out tips

#since IQ-TREE occasionally reroots trees, have to reroot back by outgroup in order for the results to make sense
presentouttaxa <- reftree$tip.label[reftree$tip.label %in% outtaxa]
if (length(presentouttaxa) == 1){
	outgroupTipID <- which(reftree$tip.label == presentouttaxa)
	outgroupMRCA <- reftree$edge[reftree$edge[,2] == outgroupTipID,1]
} else {
	outgroupMRCA <- getMRCA(reftree, presentouttaxa)
}
if (outgroupMRCA != reftree$edge[1,1]){
  # resolve root command added to ensure correct rooting with outgroup taxa:
	reftree <- root(reftree, node= outgroupMRCA, edgelabel = T, resolve.root=TRUE)
}
# Potential future issue: what if there are no outgroup taxa represented for contig?
# Current data filtered (01_FilterByTaxa step) to include only contigs representing all groups.

# Locate the node of interest:
# focal taxa represented by current contig - subsets list of focal taxa:
presentTestTaxa <- reftree$tip.label[reftree$tip.label %in% filtertaxa]
# Find the MRCA of the focal taxa and select ONE NODE DEEPER (to look at alternative topology amongst groups)
if (length(presentTestTaxa) == 1) {
	nodeToRetrieve <- as.numeric (reftree$node.label[reftree$edge[reftree$edge[,2] == which (reftree$tip.label %in% presentTestTaxa),1]-length(reftree$tip.label)])
	debug_opt <- 1
} else {
  # MRCA of focal taxa ## (This is the node of interest for group monophyly question)
	taxonNode <- getMRCA(reftree, presentTestTaxa)
	OneNodeDeeper <- reftree$edge[reftree$edge[,2] == taxonNode,1]
	#find corresponding node in stat table (because node numbers are different in R and change at rooting):
	nodeToRetrieve <- as.numeric (reftree$node.label[OneNodeDeeper-length(reftree$tip.label)])
	#for monophyly question:
	#nodeToRetrieve <- as.numeric (reftree$node.label[taxonNode-length(reftree$tip.label)])
	debug_opt <- 2
}

SCFofInterest <- stattable[stattable$ID == nodeToRetrieve,1:8]
#writes to standard out which is redirected (by iqtree_array.sh) to an scf_contigID file
write(paste(c(SCFofInterest,debug_opt),collapse=","),file="")
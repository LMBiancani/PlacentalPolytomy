library(ape)
library(phytools)
args = commandArgs(trailingOnly=TRUE)
sptree <- read.tree(args[1])
genetrees <- read.tree(args[2])
outname <- args[3]
outtrees <- list()



sptree <- chronos(sptree)

for (x in 1:length(genetrees)){
	
		
	pruned_sptree <- drop.tip(sptree, which(!(sptree$tip.label %in% genetrees[[x]]$tip.label)))
	pruned_sptree
	pruned_sptree$edge.length <- pruned_sptree$edge.length/max(nodeHeights(pruned_sptree)[,2])*1.0
	outtrees[[x]] <- pruned_sptree

}
class(outtrees) <- "multiPhylo"

write.tree(outtrees, outname)


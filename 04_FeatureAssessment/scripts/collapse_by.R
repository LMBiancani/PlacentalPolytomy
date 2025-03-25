# A script to collapse gene trees by support
#
args = commandArgs(trailingOnly=TRUE)
if (length(args) == 0){
  cat("Syntax: Rscript collapse_by.R [path to trees] [support type] [threshold] [output_name]\n")
  cat("Example: Rscript collapse_by.R trees.tre ufboot 50 outtrees.tre\n")
  quit()
}

library(ape)
#A function to collapse a tree
collapse_nodes <- function(t1, support_type, threshold){
	if (support_type == "sh-alrt") {
		support_vector <- as.numeric(sapply(strsplit(t1$node.label, "/"), function(y) y[1]))
	} else if (support_type == "ufboot") {
		support_vector <- as.numeric(sapply(strsplit(t1$node.label, "/"), function(y) y[2]))
	} else {
		print("incorrect command line parameter support type")
	}
  for (i in 1:t1$Nnode){
    if (!is.na(support_vector[i]) & support_vector[i]<=threshold){
      t1$edge.length[t1$edge[,1] == length(t1$tip.label)+i] <- t1$edge.length[t1$edge[,1] == length(t1$tip.label)+i] + t1$edge.length[which(t1$edge[,2] == length(t1$tip.label)+i)]
      t1$edge.length[which(t1$edge[,2] == length(t1$tip.label)+i)] <- 0
    }
  }
  t2 <- di2multi(t1)
  return(t2)
}

#read trees and parse other arguments
trees <- read.tree(args[1])
support_type <- args[2]
threshold <- as.numeric(args[3])
outtrees_name <- args[4]

#loop over trees checking if nodelabels present
outtrees <- list()
c <- 1
for (f in 1:length(trees)){
  if (!is.null(trees[[f]]$node.label)){
    outtrees[[c]] <- collapse_nodes(trees[[f]], support_type, threshold)
    c <- c + 1
  }
}
#save the results
class(outtrees) <- "multiPhylo"
write.tree(outtrees, outtrees_name)
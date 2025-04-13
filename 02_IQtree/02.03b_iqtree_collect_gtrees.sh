#!/bin/bash
#SBATCH --job-name="IQout"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

## UPDATE PATHS as necessary

# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# path to output folder for IQ-TREE
OUTPUT=$PROJECT/output/02_iqtree_assessment
# path to array files (array_list.txt and aligned_loci_list_* created by 02.00_iqtree_prep.sh)
ARRAY=$OUTPUT/02.00_array_prep_files
# paths to individual gene tree output directory created by 02.00_iqtree_prep.sh:
GT_OUT=$OUTPUT/02.03_gene_trees/individual_gtrees

cd $GT_OUT
date
# collect all individual loci (gene tree) names
> ../gtrees.txt; cat $ARRAY/array_list.txt | while read line1; do cat $ARRAY/${line1} >> ../gtrees.txt; done
# combines all individual gene trees into a single file
> ../gtrees.tre; cat ../gtrees.txt | while read line; do cat $GT_OUT/inference_${line}.treefile >> ../gtrees.tre; done
date

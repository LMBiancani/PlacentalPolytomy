#!/bin/bash
#SBATCH --job-name="sptree"
#SBATCH --time=10:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=5   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=48G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[0-19]%20

# Update Paths:
out=/data/schwartzlab/Biancani/Phylo_ML/output
wd=/data/schwartzlab/Biancani/Phylo_ML/01_feature_assessment
prune_script_path=$wd/scripts/prune_tree.R
# Path to concatenated species tree for all loci:
species_tree_file="/data/schwartzlab/Biancani/Phylo_ML/output/all_loci/concatenated_subsets/inference_all_loci.treefile"
#species_tree_file="./iqtree_concattree/inference.treefile" #species tree for each subset

date
module purge
module load R/4.0.3-foss-2020b

#Set Up Subset Paths Based on the Job Array Task ID
subset=$(printf "%02d\n" $((SLURM_ARRAY_TASK_ID + 1)))
path=$out/subset_$subset
cd $path
pwd

gene_tree_file="inferred_gene_trees"
pruned_output_file="./pruned_species_trees.tre"

cat $(sed -n p $path/alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') > ${gene_tree_file}".txt"
echo "alignment files concatenated: gene_tree_file.txt"
cat $(cat $(sed -n p $path/alignmentGroups/array_list.txt | awk '{print "./alignmentGroups/"$0}') | awk '{print "./iqtree_genetrees/inference_"$0".treefile"}') > ${gene_tree_file}".tre"
echo "gene tree file created: gene_tree_file.tre"

Rscript ${prune_script_path} ${species_tree_file} ${gene_tree_file}".tre" ${pruned_output_file}
date

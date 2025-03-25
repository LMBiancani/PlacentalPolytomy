#!/bin/bash
#SBATCH --job-name="cleanup"
#SBATCH --time=2:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[0-19]%20

out=/data/schwartzlab/Biancani/Phylo_ML/output

subset=$(printf "%02d\n" $((SLURM_ARRAY_TASK_ID + 1)))
path=$out/subset_$subset
cd $path
pwd

[ -f inferred_gene_trees.txt ] && rm inferred_gene_trees.txt
[ -f inferred_gene_trees.tre ] && rm inferred_gene_trees.tre
[ -f pruned_species_trees.tre ] && rm pruned_species_trees.tre

#!/bin/bash
#SBATCH --job-name="Astr"
#SBATCH --time=2:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[0-19]%20

# Update Paths:
out=/data/schwartzlab/Biancani/Phylo_ML/output
astral_path="/data/schwartzlab/Biancani/Software/ASTRAL/Astral/astral.5.7.8.jar"
wd=/data/schwartzlab/Biancani/Phylo_ML/01_feature_assessment
collapser_path=$wd/scripts/collapse_by.R

#Set Up Subset Paths Based on the Job Array Task ID
subset=$(printf "%02d\n" $((SLURM_ARRAY_TASK_ID + 1)))
path=$out/subset_$subset

# Paths to input files:
gene_tree_path="$path/inferred_gene_trees.tre"

module load R/4.0.3-foss-2020b
date

cd $path
pwd
mkdir -p astral_tree
cd astral_tree
pwd
grep "/" ${gene_tree_path} > filtered.tre
Rscript ${collapser_path} filtered.tre sh-alrt 0 collapsed_trees.tre
rm filtered.tre
java -Xmx5000M -jar ${astral_path} -i collapsed_trees.tre -o astral.tre -t 4 2>astral.log
rm collapsed_trees.tre
date

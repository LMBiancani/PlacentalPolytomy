#!/bin/bash
#SBATCH --job-name="assess"
#SBATCH --time=120:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=50G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[0-19]%20

# Update Paths:
out=/data/schwartzlab/Biancani/Phylo_ML/output
wd=/data/schwartzlab/Biancani/Phylo_ML/01_feature_assessment
assesser_path=$wd/scripts/assess_gene_properties.R

# Set Up Subset Paths Based on the Job Array Task ID
subset=$(printf "%02d\n" $((SLURM_ARRAY_TASK_ID + 1)))
path=$out/subset_$subset
aligned_loci_path=$path/alignments
inferred_gene_trees=$path/inferred_gene_trees.tre
gene_tree_names=$path/inferred_gene_trees.txt
pruned_trees_path=$path/pruned_species_trees.tre
amas_output=$path/amas_output.txt
rate_assessment_path=$path/rate_assessment
fastsp_output=$path/fastsp_output.csv

module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2
date

cd $path
pwd
outfile=ML_data.txt
Rscript ${assesser_path} ${aligned_loci_path}/ ${inferred_gene_trees} ${gene_tree_names} ${pruned_trees_path} ${amas_output} ${rate_assessment_path}/ ${outfile} ${fastsp_output}

date

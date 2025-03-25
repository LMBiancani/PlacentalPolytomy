#!/bin/bash
#SBATCH --job-name="assess"
#SBATCH --time=12:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=50G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

# Update Paths:
out=/data/schwartzlab/Biancani/Phylo_ML/output
wd=/data/schwartzlab/Biancani/Phylo_ML/01_feature_assessment
assesser_path=$wd/scripts/assess_gene_properties.R
outfile=ML_data.txt
all_loci_path=$out/all_loci

module load R-bundle-Bioconductor/3.16-foss-2022b-R-4.2.2
date 

for subset in $out/subset_*; do
  # Update Paths to input files:
	aligned_loci_path=$subset/alignments
  inferred_gene_trees=$subset/inferred_gene_trees.tre
  gene_tree_names=$subset/inferred_gene_trees.txt
  pruned_trees_path=$subset/pruned_species_trees.tre
  amas_output=$subset/amas_output.txt
  rate_assessment_path=$subset/rate_assessment
  fastsp_output=$subset/fastsp_output.csv
  
  cd $subset
  pwd
  Rscript ${assesser_path} ${aligned_loci_path}/ ${inferred_gene_trees} ${gene_tree_names} ${pruned_trees_path} ${amas_output} ${rate_assessment_path}/ ${outfile} ${fastsp_output}
done

#combine assessment files for all loci:

all_out=$all_loci_path/all_loci_$outfile

# Get header from the first file
head -n 1 $out/subset_01/$outfile > "$all_out"

# Append data from all files, skipping headers
tail -n +2 -q $out/subset_*/$outfile >> "$all_out"

echo "Combined file created at: $all_out"

date


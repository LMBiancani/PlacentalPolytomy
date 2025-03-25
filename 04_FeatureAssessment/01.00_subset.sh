#!/bin/bash
#SBATCH --job-name="subset"
#SBATCH --time=100:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

# Update Paths:
out=/data/schwartzlab/Biancani/Phylo_ML/output
aligned_loci_path=/data/schwartzlab/Biancani/PlacentalPolytomy/output/01_SISRS_loci_filtered
subset_size=5500  # Number of alignment per subset

# Create output directory:
mkdir -p $out
cd $out
date
pwd

# Create destination alignment sub-directories and subset files
counter=0 #initiate counter to track processed files
for file in $aligned_loci_path/*; do ##iterate over each file in aligned_loci_path
  dir_num=$(printf "%02d" $((counter / $subset_size + 1))) #calculate the subdirectory number starting with "01"
  dest_dir=subset_$dir_num/alignments
  mkdir -p $dest_dir
  cp $file $dest_dir/
  ((counter++)) #increment counter by 1 after each file is processed
done

echo "Number of alignment subdirectories created:"
echo $dir_num


#!/bin/bash
#SBATCH --job-name="prep"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

out=/data/schwartzlab/Biancani/Phylo_ML/output

for subset in $out/subset_*; do
	echo $subset
  cd $subset/iqtree_genetrees
  mv * /data/schwartzlab/Biancani/Trash/
done

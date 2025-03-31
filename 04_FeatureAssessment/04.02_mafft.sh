#!/bin/sh
#SBATCH --job-name="realign"
#SBATCH --time=196:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=4   # processor core(s) per node
#SBATCH --mem=120G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

out=/data/schwartzlab/Biancani/Phylo_ML/output

date
module purge
module load MAFFT/7.475-gompi-2020b-with-extensions

for subset in $out/subset_*; do
  cd $subset
  pwd
  for alignment in alignments/*; do
    name=$(basename $alignment)
    mafft --auto --thread 4 $alignment > $subset/re_alignments/$name
  done
done

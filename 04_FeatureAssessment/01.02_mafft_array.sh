#!/bin/sh
#SBATCH --job-name="realign"
#SBATCH --time=96:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=4   # processor core(s) per node
#SBATCH --mem=120G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=[0-19]%20

out=/data/schwartzlab/Biancani/Phylo_ML/output

date
module purge
module load MAFFT/7.475-gompi-2020b-with-extensions

subset=$(printf "%02d\n" $((SLURM_ARRAY_TASK_ID + 1)))
path=$out/subset_$subset
cd $path
pwd
for alignment in alignments/*; do
  name=$(basename $alignment)
  mafft --auto --thread 4 $alignment > $path/re_alignments/$name
done


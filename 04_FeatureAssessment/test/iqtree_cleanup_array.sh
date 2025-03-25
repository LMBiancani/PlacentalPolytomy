#!/bin/bash
#SBATCH --job-name="cleanup"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
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

cd iqtree_genetrees
mkdir -p other_outfiles

for file in *fasta.[^t]*; do
mv $file other_outfiles/
done

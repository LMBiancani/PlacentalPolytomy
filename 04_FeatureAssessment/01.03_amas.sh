#!/bin/bash
#SBATCH --job-name="amas"
#SBATCH --time=48:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=12   # processor core(s) per node
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

out=/data/schwartzlab/Biancani/Phylo_ML/output
amas=/data/schwartzlab/Biancani/Software/AMAS/amas/AMAS.py
cores=12

date
module purge
module load Python/3.7.4-GCCcore-8.3.0

for subset in $out/subset_*; do
cd $subset
python $amas summary -c $cores -o amas_output.txt -f fasta -d dna -i alignments/*
done
date


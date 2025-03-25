#!/bin/bash
#SBATCH --job-name="FastSP"
#SBATCH --time=124:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=2   # processor core(s) per node
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

# Update Path:
out=/data/schwartzlab/Biancani/Phylo_ML/output
fastsp="/data/schwartzlab/Biancani/Software/FastSP/FastSP.jar"

date
module purge
module load all/Java/17.0.2

for subset in $out/subset_*; do
  cd $subset
  pwd
  > fastsp_output.csv
  for alignment in alignments/*; do
    file=$(basename $alignment)
    echo $file","$(java -jar ${fastsp} -r alignments/$file -e re_alignments/$file | grep "SP-Score" | sed 's/SP-Score //g')  >> fastsp_output.csv
  done
done
date


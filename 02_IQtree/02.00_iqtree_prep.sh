#!/bin/bash
#SBATCH --job-name="IQprep"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

## UPDATE PATHS:
# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# path to FILTERED SISRS loci (aligned contigs):
INPUT=$PROJECT/output/01_SISRS_loci_filtered
# path to output folder for IQ-TREE (will be created by script if necessary):
OUTPUT=$PROJECT/output/02_iqtree_assessment

## UPDATE PARAMETERS:
# number of simultaneous tasks for subsequent array jobs:
TASKS=40

mkdir -p ${OUTPUT}
cd ${OUTPUT}

# create output directories for array jobs:
mkdir -p 02.01_compare_hypotheses/scf
mkdir -p 02.01_compare_hypotheses/likelihood
mkdir -p 02.02_concat_trees
mkdir -p 02.03_gene_trees/individual_gtrees

# extract filenames from INPUT and split into bins of 4000 loci
ls ${INPUT} | rev | cut -f1 -d/ | rev | split -l 4000 - aligned_loci_list_
arrayN=$(ls aligned_loci_list_* | wc -l)
ls aligned_loci_list_* > array_list.txt
if [ $arrayN -lt $TASKS ]
    then
      TASKS=$arrayN
fi

echo "#SBATCH --array=[1-${arrayN}]%${TASKS}"
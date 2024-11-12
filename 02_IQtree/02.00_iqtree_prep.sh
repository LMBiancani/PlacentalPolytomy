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
## PREP for 02.02_iqtree_array_concat.sh:
CAT_OUT=$OUTPUT/02.02_concat_trees

# UPDATE PARAMETERS:
# number of simultaneous tasks for subsequent array jobs:
TASKS=40

mkdir -p ${OUTPUT}
cd ${OUTPUT}
mkdir scf
# extract filenames from INPUT and split into bins of 4000 loci
ls ${INPUT} | rev | cut -f1 -d/ | rev | split -l 4000 - aligned_loci_list_
arrayN=$(ls aligned_loci_list_* | wc -l)
ls aligned_loci_list_* > array_list.txt
if [ $arrayN -lt $TASKS ]
    then
      TASKS=$arrayN
fi

## PREP for 02.02_iqtree_array_concat.sh:
mkdir -p $CAT_OUT
ln $OUTPUT/array_list.txt $CAT_OUT/
ln $OUTPUT/aligned_loci_list_* $CAT_OUT/

echo "#SBATCH --array=[1-${arrayN}]%${TASKS}"

#!/bin/bash
#SBATCH --job-name="IQcat"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 10
#SBATCH --mem-per-cpu=6G
#SBATCH --array=[1-28]%28 ## UPDATE based on output from 02.00_iqtree_prep.sh
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

## UPDATE PATHS as necessary:

# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# path to output folder for IQ-TREE (must be location of array_list.txt and aligned_loci_list_* created by iqtree prep script)
OUTPUT=$PROJECT/output/02_iqtree_assessment
# path to FILTERED SISRS loci (aligned contigs):
INPUT=$PROJECT/output/01_SISRS_loci_filtered
# path to IQ-TREE executale:
IQTREE="/data/schwartzlab/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"
# location of iqtree scripts:
scripts_dir=$PROJECT/02_IQtree
# path to file containing alternative hypotheses trees:
trees_to_eval=$scripts_dir/hypothesis_trees/Polytomy_Placental_Hypotheses.tree
# path to AMAS executable:
AMAS="/data/schwartzlab/Biancani/Software/AMAS/amas/AMAS.py"
# output for concatenated trees (directory and the input files it contains were created by 02.00_iqtree_prep.sh)
CAT_OUT=$OUTPUT/02.02_concat_trees

cd ${CAT_OUT}
date

module purge
module load Python/3.7.4-GCCcore-8.3.0

fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)

# generates list of paths to infiles
infiles=$(cat ${fileline} | while read line; do echo ${INPUT}/${line}; done | paste -sd" ")

#amas concatenated
python3 ${AMAS} concat -f fasta -d dna --out-format fasta --part-format raxml -i $infiles -t concatenated_${SLURM_ARRAY_TASK_ID}.fasta -p partitions_${SLURM_ARRAY_TASK_ID}.txt

module purge
module load R/4.0.3-foss-2020b

Rscript ${scripts_dir}trimTrees.R concatenated_${SLURM_ARRAY_TASK_ID}.fasta ${trees_to_eval} ./trees_${SLURM_ARRAY_TASK_ID}.tre

#${IQTREE} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -z ./trees_${SLURM_ARRAY_TASK_ID}.tre -pre calcLnL_${SLURM_ARRAY_TASK_ID} -n 0 -m GTR+G -wsl
#${IQTREE} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -pre inference_${SLURM_ARRAY_TASK_ID} -m GTR+G -bb 1000 -alrt 1000 -wsr

for i in $(seq 3) #iterate through 3 hypothesis trees
do
  sed -n ${i}p ./trees_${SLURM_ARRAY_TASK_ID}.tre > ./tree${i}_${SLURM_ARRAY_TASK_ID}.tre
  ${IQTREE} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -pre calcLnL${i}_${SLURM_ARRAY_TASK_ID} -g ./tree${i}_${SLURM_ARRAY_TASK_ID}.tre -m GTR+G -redo -wsl
done

${IQTREE} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -pre inference_${SLURM_ARRAY_TASK_ID} -m GTR+G -bb 1000 -alrt 1000 -redo -wsr

date
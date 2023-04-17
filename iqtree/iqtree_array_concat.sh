#!/bin/bash
#SBATCH --job-name="IQcat"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 10
#SBATCH --mem-per-cpu=6G
#SBATCH --array=[1-28]%28
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

## update array line above based on output of iqtree prep script

# UPDATE:
# path to output folder for iqtree (must be location of array_list.txt and aligned_loci_list_* created by iqtree prep script)
array_work_folder=/data/schwartzlab/Biancani/PlacentalPolytomy/output/iqtree_assessment
# path to FILTERED SISRS loci (aligned contigs) folder:
aligned_loci_path=/data/schwartzlab/Biancani/PlacentalPolytomy/output/SISRS_out_filtered
#location of iqtree executable:
iqtree_exe="/data/schwartzlab/alex/andromeda_tools/iqtree-2.1.2-Linux/bin/iqtree2"
# location of iqtree scripts:
scripts_dir=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree
# path to file containing alternative hypotheses trees:
trees_to_eval=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree/hypothesis_trees/Polytomy_Placental_Hypotheses.tree
# location of amas executable:
path_to_amas="/data/schwartzlab/Biancani/AMAS/amas/AMAS.py"


cd $array_work_folder
mkdir -p concat_trees
cd concat_trees
cp --update $array_work_folder/array_list.txt .
cp --update $array_work_folder/aligned_loci_list_* .

date

module purge
module load Python/3.7.4-GCCcore-8.3.0

fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)

# generates list of paths to infiles
infiles=$(cat ${fileline} | while read line; do echo ${aligned_loci_path}/${line}; done | paste -sd" ")

#amas concatenated
python3 ${path_to_amas} concat -f fasta -d dna --out-format fasta --part-format raxml -i $infiles -t concatenated_${SLURM_ARRAY_TASK_ID}.fasta -p partitions_${SLURM_ARRAY_TASK_ID}.txt

module purge
module load R/4.0.3-foss-2020b

Rscript ${scripts_dir}trimTrees.R concatenated_${SLURM_ARRAY_TASK_ID}.fasta ${trees_to_eval} ./trees_${SLURM_ARRAY_TASK_ID}.tre

#${iqtree_exe} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -z ./trees_${SLURM_ARRAY_TASK_ID}.tre -pre calcLnL_${SLURM_ARRAY_TASK_ID} -n 0 -m GTR+G -wsl
#${iqtree_exe} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -pre inference_${SLURM_ARRAY_TASK_ID} -m GTR+G -bb 1000 -alrt 1000 -wsr

for i in $(seq 3) #step through 3 hypothesis trees
do
  sed -n ${i}p ./trees_${SLURM_ARRAY_TASK_ID}.tre > ./tree${i}_${SLURM_ARRAY_TASK_ID}.tre
  ${iqtree_exe} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -pre calcLnL${i}_${SLURM_ARRAY_TASK_ID} -g ./tree${i}_${SLURM_ARRAY_TASK_ID}.tre -m GTR+G -redo -wsl
done

${iqtree_exe} -nt 10 -s concatenated_${SLURM_ARRAY_TASK_ID}.fasta -spp partitions_${SLURM_ARRAY_TASK_ID}.txt -pre inference_${SLURM_ARRAY_TASK_ID} -m GTR+G -bb 1000 -alrt 1000 -redo -wsr

date
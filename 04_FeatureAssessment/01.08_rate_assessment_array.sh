#!/bin/bash
#SBATCH --job-name="submit_jobs"
#SBATCH --time=1:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

# UPDATE:
out=/data/schwartzlab/Biancani/Phylo_ML/output

### begin creating job script (Single quotes ('EOF') prevent variable expansion inside the here-document)
cat << 'EOF' > HParr.sh
#!/bin/bash
#SBATCH --job-name="HParr"
#SBATCH --time=72:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=1-22 #based on the number of alignmentGroups in each subset

# UPDATE:
out=/data/schwartzlab/Biancani/Phylo_ML/output
wd=/data/schwartzlab/Biancani/Phylo_ML/01_feature_assessment

## location of HyPhy batch script:
batch_script=$wd/scripts/HyPhy/2.5.33-gompi-2020b/share/hyphy/TemplateBatchFiles/LEISR.bf
#batch_script="/opt/software/HyPhy/2.5.33-gompi-2020b/share/hyphy/TemplateBatchFiles/LEISR.bf"
## path to subset directory is passed to job scrip using export $subset
aligned_loci_path=$subset/alignments
iqtree_log_path=$subset/iqtree_genetrees
pruned_trees_path=$subset/pruned_species_trees.tre
gene_tree_names=$subset/inferred_gene_trees.txt

date
cd $subset/rate_assessment
pwd

module purge
module load R/4.0.3-foss-2020b
module load HyPhy/2.5.33-gompi-2020b

#create a series of arrays corresponding to each line in the array_list.txt file
fileline=$(sed -n "${SLURM_ARRAY_TASK_ID}"p $subset/alignmentGroups/array_list.txt)
echo "File line:${fileline} "
cat $subset/alignmentGroups/${fileline} | while read line; do
	echo $line #locus file
  if [[ ! -f "${iqtree_log_path}/inference_${line}.log" ]]; then
    echo "Error: Log file not found: ${iqtree_log_path}/inference_${line}.log" >&2
    exit 1
  fi
	best_model_param=$(grep "Bayesian Information Criterion:" ${iqtree_log_path}/inference_${line}.log | awk '{print $4}')
  best_model=$(echo ${best_model_param} | cut -f1 -d+)
  echo "Best Model: $best_model"
	if [ "$best_model" = "HKY" ] || [ "$best_model" = "F81" ]; then useModel="HKY85"; else useModel="GTR"; fi
  echo "Model Used: $useModel"
	if [[ "$best_model_param" == *"+"* ]]; then best_param=$(echo ${best_model_param} | cut -f2- -d+); else best_param=""; fi	
  echo "Best Model Parameter: $best_param"
	if [[ "$best_param" == *"G"* ]] || [[ "$best_param" == *"R"* ]]; then useRVAS="Gamma"; else useRVAS="No"; fi
  echo "Rate Variation Across Sites: $useRVAS"
	treefile="temp_tree_${SLURM_ARRAY_TASK_ID}.tre"
	loc_name=$(echo ${line} )
  if ! grep -q "${loc_name}" "${gene_tree_names}"; then
    echo "Error: ${loc_name} not found in ${gene_tree_names}" >&2
    exit 1
  fi
  echo ${loc_name} ${gene_tree_names}
  grep -wn "${loc_name}" ${gene_tree_names}
	sed -n $(grep -wn ${loc_name} ${gene_tree_names} | cut -f1 -d:)p ${pruned_trees_path} > ${treefile}
  echo "Running HyPhy."
	hyphy ${batch_script} ${aligned_loci_path}/${line} ${treefile} Nucleotide ${useModel} ${useRVAS} 
	mv ${aligned_loci_path}/${line}.LEISR.json .
	rm ${treefile}
done
date
EOF
### end creating job script
echo "HParr.sh created"

# Iterate through subset paths and submit above job for each:
for subset in $out/subset_*; do
	echo $subset
	export subset=$subset # pass subset path to slurm submit
	sbatch HParr.sh # submit job
done

rm HParr.sh
date

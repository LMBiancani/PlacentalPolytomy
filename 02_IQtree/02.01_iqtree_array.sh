#!/bin/bash
#SBATCH --job-name="IQarr"
#SBATCH --time=48:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --array=[1-28]%28 ## UPDATE based on output from 02.00_iqtree_prep.sh
#SBATCH --mail-user="biancani@uri.edu" ## UPDATE
#SBATCH --mail-type=ALL

## UPDATE PATHS as necessary:

# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# location of iqtree scripts:
scripts_dir=$PROJECT/02_IQtree
# path to FILTERED SISRS loci (aligned contigs):
INPUT=$PROJECT/output/01_SISRS_loci_filtered
# path to file containing alternative hypotheses trees:
trees_to_eval=$scripts_dir/hypothesis_trees/Polytomy_Placental_Hypotheses.tree
# path to IQ-TREE executale:
IQTREE="/data/schwartzlab/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"
# path to output folder for IQ-TREE
# (must be location of array_list.txt and aligned_loci_list_* created by iqtree prep script)
OUTPUT=$PROJECT/output/02_iqtree_assessment
# paths to output directories created by 02.00_iqtree_prep.sh:
hypotheses=$OUTPUT/02.01_compare_hypotheses
scf=${hypotheses}/scf
likelihood=${hypotheses}/likelihood

## Specify taxon list for each hypothesis tree:
# For Placental root question: Determine which 2 out of 3 groups are sisters for each hypothesis and select one of the sisters.
# List 1 (Afrotheria Out) = Xenarthra
focal_tips1=$scripts_dir/hypothesis_trees/tips_Xenarthra.txt
# List 2 (Boreoeutheria Out) = Afrotheria
focal_tips2=$scripts_dir/hypothesis_trees/tips_Afrotheria.txt
# List 3 (Xenarthra Out) = Boreoeutheria
focal_tips3=$scripts_dir/hypothesis_trees/tips_Boreoeutheria.txt
# Outgroup taxa list:
outgroup_tips=$scripts_dir/hypothesis_trees/tips_Outgroup.txt

module load R/4.0.3-foss-2020b

cd ${hypotheses}
date

#generate list of filenames for aligned loci:
fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p ${OUTPUT}/array_list.txt)

#create output csv file for each batch fasta file created by prep script (aka each slurm task):
> $likelihood/LnLs_${SLURM_ARRAY_TASK_ID}.csv

cat $OUTPUT/${fileline} | while read line
do
	echo $line
	Rscript ${scripts_dir}/trimTrees.R ${INPUT}/${line} ${trees_to_eval} ./trees_${line}.tre
	
	# iterate through 3 constraint trees:
	for t in 1 2 3; do
	  sed -n ${t}p ./trees_${line}.tre > ./tree${t}_${line}.tre # select constraint tree from tree file
	  ${IQTREE} -nt 1 -t ./tree${t}_${line}.tre -s ${INPUT}/${line} --scf 500 --prefix concord${t}_${line}
	  if [ "$t" -eq 1 ]; then
	    echo "ID,sCF,sCF_N,sDF1,sDF1_N,sDF2,sDF2_N,sN,debug" > ${scf}/scf_${line} # add header to scf output file
	  fi
	  focal_tips_var="focal_tips${t}"
	  Rscript ${scripts_dir}/getSCF.R concord${t}_${line}.cf.branch concord${t}_${line}.cf.stat ${!focal_tips_var} ${outgroup_tips} >> ${scf}/scf_${line}
	  ${IQTREE} -nt 1 -s ${INPUT}/${line} -pre calcLnL_${line} -g ./tree${t}_${line}.tre -m GTR+G -redo #calculate likelihoods
	  echo $line","$(grep "BEST SCORE FOUND" calcLnL_${line}.log | cut -f2 -d: ) >> ${likelihood}/LnLs_${SLURM_ARRAY_TASK_ID}.csv # pulls likelihood from file
	  rm concord${t}_${line}.log concord${t}_${line}.cf.branch concord${t}_${line}.cf.stat concord${t}_${line}.cf.tree concord${t}_${line}.cf.tree.nex
	  rm ./tree${t}_${line}.tre
  done
	
	# rm other potential output files
	# (while preventing the return of an error exit status if file does not exist)
	for file in trees_${line}.tre calcLnL_${line}.ckp.gz calcLnL_${line}.iqtree calcLnL_${line}.log calcLnL_${line}.treefile calcLnL_${line}.trees calcLnL_${line}.uniqueseq.phy calcLnL_${line}.parstree
	do
	  if [ -f $file ]; then # test to see if file exists
	    rm $file
	  else
	    echo "rm: cannot remove $file: No such file or directory"
	  fi
	done
done
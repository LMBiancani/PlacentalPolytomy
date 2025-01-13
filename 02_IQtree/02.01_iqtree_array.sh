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


## UPDATE PATHS:
# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# path to output folder for IQ-TREE (will be created by script if necessary):
OUTPUT=$PROJECT/output/02_iqtree_assessment
# path to FILTERED SISRS loci (aligned contigs):
INPUT=$PROJECT/output/01_SISRS_loci_filtered
#path to IQ-TREE executale:
IQTREE="/data/schwartzlab/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"



## output for concatenated trees (directory setup by 02.00_iqtree_prep.sh)
CAT_OUT=$OUTPUT/02.02_concat_trees

******* left off here updating Paths...

# UPDATE:

# location of iqtree scripts:
scripts_dir=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree
# path to file containing alternative hypotheses trees:
trees_to_eval=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree/hypothesis_trees/Polytomy_Placental_Hypotheses.tree
# Specify taxon list for each hypothesis tree:
# For Placental root question: Determine which 2 out of 3 groups are sisters for each hypothesis and select one of the sisters.
# List 1 (Afrotheria Out) = Xenarthra
focal_tips1=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree/hypothesis_trees/tips_Xenarthra.txt
# List 2 (Boreoeutheria Out) = Afrotheria
focal_tips2=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree/hypothesis_trees/tips_Afrotheria.txt
# List 3 (Xenarthra Out) = Boreoeutheria
focal_tips3=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree/hypothesis_trees/tips_Boreoeutheria.txt
# Outgroup taxa list:
outgroup_tips=/data/schwartzlab/Biancani/PlacentalPolytomy/iqtree/hypothesis_trees/tips_Outgroup.txt

cd ${OUTPUT}

date
module load R/4.0.3-foss-2020b

#generate list of filenames for aligned loci:
fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p array_list.txt)

#create output csv file for each batch fasta file created by prep script (aka each slurm task):
> LnLs_${SLURM_ARRAY_TASK_ID}.csv

cat ${fileline} | while read line
do
	echo $line
	Rscript ${scripts_dir}/trimTrees.R ${INPUT}/${line} ${trees_to_eval} ./trees_${line}.tre
	
	sed -n 1p ./trees_${line}.tre > ./tree1_${line}.tre # select constraint tree from tree file
	${IQTREE} -nt 1 -t ./tree1_${line}.tre -s ${INPUT}/${line} --scf 500 --prefix concord1_${line}
	echo "ID,sCF,sCF_N,sDF1,sDF1_N,sDF2,sDF2_N,sN,debug" > scf/scf_${line}
	Rscript ${scripts_dir}getSCF.R concord1_${line}.cf.branch concord1_${line}.cf.stat ${focal_tips1} ${outgroup_tips} >> scf/scf_${line}
	${IQTREE} -nt 1 -s ${INPUT}/${line} -pre calcLnL_${line} -g ./tree1_${line}.tre -m GTR+G -redo #calculate likelihoods
	echo $line","$(grep "BEST SCORE FOUND" calcLnL_${line}.log | cut -f2 -d: ) >> LnLs_${SLURM_ARRAY_TASK_ID}.csv #pulls likelihood from file
	rm concord1_${line}.log concord1_${line}.cf.branch concord1_${line}.cf.stat concord1_${line}.cf.tree concord1_${line}.cf.tree.nex
	rm ./tree1_${line}.tre
	
	sed -n 2p ./trees_${line}.tre > ./tree2_${line}.tre
	${IQTREE} -nt 1 -t ./tree2_${line}.tre -s ${INPUT}/${line} --scf 500 --prefix concord2_${line}
	Rscript ${scripts_dir}getSCF.R concord2_${line}.cf.branch concord2_${line}.cf.stat ${focal_tips2} ${outgroup_tips} >> scf/scf_${line}
	${IQTREE} -nt 1 -s ${INPUT}/${line} -pre calcLnL_${line} -g ./tree2_${line}.tre -m GTR+G -redo
	echo $line","$(grep "BEST SCORE FOUND" calcLnL_${line}.log | cut -f2 -d: ) >> LnLs_${SLURM_ARRAY_TASK_ID}.csv
	rm concord2_${line}.log concord2_${line}.cf.branch concord2_${line}.cf.stat concord2_${line}.cf.tree concord2_${line}.cf.tree.nex
	rm ./tree2_${line}.tre

	sed -n 3p ./trees_${line}.tre > ./tree3_${line}.tre
	${IQTREE} -nt 1 -t ./tree3_${line}.tre -s ${INPUT}/${line} --scf 500 --prefix concord3_${line}
	Rscript ${scripts_dir}getSCF.R concord3_${line}.cf.branch concord3_${line}.cf.stat ${focal_tips3} ${outgroup_tips} >> scf/scf_${line}
	${IQTREE} -nt 1 -s ${INPUT}/${line} -pre calcLnL_${line} -g ./tree3_${line}.tre -m GTR+G -redo
	echo $line","$(grep "BEST SCORE FOUND" calcLnL_${line}.log | cut -f2 -d: ) >> LnLs_${SLURM_ARRAY_TASK_ID}.csv
	rm concord3_${line}.log concord3_${line}.cf.branch concord3_${line}.cf.stat concord3_${line}.cf.tree concord3_${line}.cf.tree.nex
	rm ./tree3_${line}.tre
	
	# rm lines re-written below to prevent returning an error exit status if file does not exist
	for file in ./trees_${line}.tre calcLnL_${line}.ckp.gz calcLnL_${line}.iqtree calcLnL_${line}.log calcLnL_${line}.treefile calcLnL_${line}.trees calcLnL_${line}.uniqueseq.phy calcLnL_${line}.parstree
	do
	  if [ -f $file ] # test to see if file exists
	  then rm $file
	  else echo "rm: cannot remove $file: No such file or directory"
	  fi
	done
done
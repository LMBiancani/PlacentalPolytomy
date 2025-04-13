#!/bin/bash
#SBATCH --job-name="IQarr"
#SBATCH --time=48:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=6G
#SBATCH --array=[1-28]%28 ## UPDATE based on output from 02.00_iqtree_prep.sh
#SBATCH --mail-user="biancani@uri.edu"
#SBATCH --mail-type=ALL

## UPDATE PATHS as necessary:

# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# location of iqtree scripts:
scripts_dir=$PROJECT/02_IQtree
# path to FILTERED SISRS loci (aligned contigs):
INPUT=$PROJECT/output/01_SISRS_loci_filtered
# path to IQ-TREE executale:
IQTREE="/data/schwartzlab/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2"

# path to output folder for IQ-TREE
OUTPUT=$PROJECT/output/02_iqtree_assessment
# path to array files (array_list.txt and aligned_loci_list_* created by 02.00_iqtree_prep.sh)
ARRAY=$OUTPUT/02.00_array_prep_files
# paths to individual gene tree output directory created by 02.00_iqtree_prep.sh:
GT_OUT=$OUTPUT/02.03_gene_trees/individual_gtrees

cd ${GT_OUT}
date

#generate list of filenames for aligned loci:
fileline=$(sed -n ${SLURM_ARRAY_TASK_ID}p $ARRAY/array_list.txt)

cat ${ARRAY}/${fileline} | while read line
do
	echo $line
	${IQTREE} -nt 1 -s ${INPUT}/${line} -pre inference_${line} -alrt 1000 -m GTR+G
	# rm unnessary output files
	# (while preventing the return of an error exit status if file does not exist)
	for file in inference_${line}.ckp.gz inference_${line}.iqtree inference_${line}.log inference_${line}.bionj inference_${line}.mldist inference_${line}.uniqueseq.phy
	do
	  if [ -f $file ]; then # test to see if file exists
	    rm $file
	  else
	    echo "rm: cannot remove $file: No such file or directory"
	  fi
	done
done

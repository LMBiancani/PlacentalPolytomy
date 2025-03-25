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
cat << 'EOF' > genetrees.sh
#!/bin/bash
#SBATCH --job-name="IQloop"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=10G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL
#SBATCH --array=1-22 #based on the number of alignmentGroups in each subset

# UPDATE:
out=/data/schwartzlab/Biancani/Phylo_ML/output
iqtree_exe=/data/schwartzlab/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2

## path to subset directory is passed to job scrip using export $subset
date
echo $subset
aligned_loci_path=$subset/alignments

#create a series of arrays corresponding to each line in the array_list.txt file
fileline=$(sed -n "${SLURM_ARRAY_TASK_ID}"p $subset/alignmentGroups/array_list.txt)
echo "File line:${fileline} "
while read line; do
	#iqtree job: Flags instruct iqtree to keep sequence identifiers as they are in the input file; to set 2 threads for parallel processing; specifies a DNA aligment file; specifies a prefix for the output files; specifies the substitution model to be used, MFP, a mixture model of amino acid frequencies; sets 1000 ultrafast bootstraps; and ets the number of replicates for the non-parametric approximate likelihood ratio test (aLRT) to 1000
	cd $subset/iqtree_genetrees
	pwd
	$iqtree_exe --keep-ident -nt 2 -s ${aligned_loci_path}/${line} -pre inference_${line} -m MFP -bb 1000 -alrt 1000
  #mkdir -p log_files
  #for file in *.log; do
  #  mv $file log_files/
  #done
  #mkdir -p other_outfiles
  #for file in *fasta.[^t]*; do
  #  mv $file other_outfiles/
  #done
done < $subset/alignmentGroups/${fileline}
date
EOF
### end creating job script
echo "genetrees.sh created"

# Iterate through subset paths and submit above job for each:
for subset in $out/subset_*; do
	echo $subset
	export subset=$subset # pass subset path to slurm submit
	sbatch genetrees.sh # submit job
done

rm genetrees.sh
date


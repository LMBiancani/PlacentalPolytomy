#!/bin/sh
#SBATCH --job-name="filter"
#SBATCH --time=30:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node - just use 1 
#SBATCH --mail-user="biancani@uri.edu" #CHANGE to your email
#SBATCH --mail-type=ALL

## UPDATE PATHS:
# path to SISRS loci (aligned contigs) folder:
LOCI=/data/schwartzlab/Biancani/PLACENTAL/SISRS_out/SISRS_Run/aligned_contigs
# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy

# path to folder containing filterByTaxa scripts:
SCRIPTS=$PROJECT/01_FilterByTaxa
# path to taxon group table (csv):
TXNGROUPS=$SCRIPTS/groups.csv
# path to output folder for filtered loci (will be created by script if necessary):
OUTPUT=$PROJECT/output/01_SISRS_loci_filtered

## UPDATE parameters:
SEQCOMPLETE=0.33 # taxon sequence completeness, (e.g. 0.33 is 33% non N)
MINTAXA=18 # minimum number taxa to be present, e.g. 18
MINGROUPS=4 # minimum number of taxon groups to be present, e.g. 4

cd $SLURM_SUBMIT_DIR

module purge
#for URI's Andromeda cluster
module load Biopython/1.78-foss-2020b 

echo "Total number of unfiltered SISRS loci:"
ls -1U $LOCI | wc -l

mkdir -p $OUTPUT
python $SCRIPTS/filter_SISRS_output.py $TXNGROUPS $LOCI $OUTPUT $SEQCOMPLETE $MINTAXA $MINGROUPS

echo "Number of filtered SISRS loci:"
ls -1U $OUTPUT | wc -l
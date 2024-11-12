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
# path to folder containing filterByTaxa scripts:
SCRIPTS=/data/schwartzlab/Biancani/PlacentalPolytomy/01_FilterByTaxa
# path to taxon group table (csv):
TXNGROUPS=/data/schwartzlab/Biancani/PlacentalPolytomy/01_FilterByTaxa/groups.csv
# path to output folder for filtered loci (will be created by script if necessary):
OUTPUT=/data/schwartzlab/Biancani/PlacentalPolytomy/output/01_SISRS_loci_filtered

cd $SLURM_SUBMIT_DIR

module purge

echo "Total number of unfiltered SISRS loci:"
ls -1U $LOCI | wc -l

echo "Number of filtered SISRS loci:"
ls -1U $OUTPUT | wc -l
#!/bin/sh
#SBATCH --job-name="download_reference"
#SBATCH --time=10:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH --mail-user="biancani@uri.edu" #CHANGE to your email
#SBATCH --mail-type=ALL

## UPDATE PATHS:
# path to project directory:
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# path to output folder for annotation (will be created by script if necessary):
OUTPUT=$PROJECT/output/03_Annotation
# path to folder for reference genome (will be created by script if necessary):
RefDir=$OUTPUT/ReferenceGenome

## UPDATE URLs:
#URL for GFF format reference annotation file: 
ANNOTATION="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/880/755/GCF_002880755.1_Clint_PTRv2/GCF_002880755.1_Clint_PTRv2_genomic.gff.gz"
#URL for fasta format reference genome:
GENOME="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/880/755/GCF_002880755.1_Clint_PTRv2/GCF_002880755.1_Clint_PTRv2_genomic.fna.gz"

mkdir -p $RefDir
cd $RefDir

for i in $ANNOTATION $GENOME
do
  #download file:
  wget --tries=0 --retry-connrefused --continue --timeout=30 --progress=dot:giga $i
  #extract filename from URL:
  name=$(echo $i | rev | cut -d '/' -f 1 | rev)
  #decompress file:
  gunzip $name
done
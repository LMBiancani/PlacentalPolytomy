#!/bin/bash
#SBATCH --job-name="IQconcat"
#SBATCH --time=172:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=20   # processor core(s) per node
#SBATCH --mem=200G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE TO user email address
#SBATCH --mail-type=ALL

out=/data/schwartzlab/Biancani/Phylo_ML/output
amas=/data/schwartzlab/Biancani/Software/AMAS/amas/AMAS.py
iqtree_exe=/data/schwartzlab/Biancani/Software/iqtree-2.1.2-Linux/bin/iqtree2

date
module purge
module load Python/3.7.4-GCCcore-8.3.0
cat_subsets=$out/all_loci/concatenated_subsets
mkdir -p $cat_subsets
cd $cat_subsets
pwd

##for each subset, copy concatenated alignments and partition files to all_loci:
for subset in $out/subset_*; do
  name=$(basename $subset)
  cp $subset/iqtree_concattree/concatenated.fasta $cat_subsets/${name}_concat.fasta
  cp $subset/iqtree_concattree/partitions.txt $cat_subsets/${name}_partition.txt
done

files=$(ls *concat.fasta)
echo "Running AMAS to concatenate subsets"
python3 ${amas} concat -f fasta -d dna --out-format fasta --part-format raxml -i ${files} -t all_loci_concatenated.fasta -p partitioned_subsets.txt

echo "creating partitions file for all concatenated loci..."
> all_loci_partitions.txt
part=0
while read -r line; do
  subset=$(echo "$line" | grep -oP '(?<=subset_)\d{2}')
  start=$(echo "$line" | grep -oP '\d+(?=-)')
  end=$(echo "$line" | grep -oP '(?<=-)\d+')
  #echo "$subset $start $end"
  file=subset_${subset}_partition.txt
  #ls $file
    while read -r l; do
      p=$(echo "$l" | grep -oP '(?<=, p)\d+(?=_SISRS)')
      contig=$(echo "$l" | grep -oP '(?<=contig-)\d+(?= =)')
      s=$(echo "$l" | grep -oP '\d+(?=-)')
      e=$(echo "$l" | grep -oP '(?<=-)\d+$')
      #echo $l
      #echo "DNA, p${p}_SISRS_contig-${contig} = ${s}-${e}"
      ((part++))
      if [[ $s -lt $start ]]; then
        s=$((s + start - 1))
        e=$((e + start - 1))
      fi
      echo "DNA, p${part}_SISRS_contig-${contig} = ${s}-${e}" >> all_loci_partitions.txt
    done < $file
  if [[ $e -ne $end ]]; then
    echo "ERROR: Loci positions do not match. Subset $subset should end at $end but actually ended at $e"
    break
  fi
done < partitioned_subsets.txt

echo "Running IQTree"
${iqtree_exe} -nt 20 -s all_loci_concatenated.fasta -spp all_loci_partitions.txt -pre inference_all_loci -m MFP -bb 1000 -alrt 1000
date


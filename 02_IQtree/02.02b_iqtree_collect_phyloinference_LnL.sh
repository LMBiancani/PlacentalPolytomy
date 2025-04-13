#!/bin/bash
#SBATCH --job-name="iqout"
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=1   # processor core(s) per node
#SBATCH -c 1
#SBATCH --mem-per-cpu=8G
#SBATCH --mail-user="biancani@uri.edu" #CHANGE THIS to your user email address
#SBATCH --mail-type=ALL

## UPDATE PATHS as necessary:

# path to project directory:
arrayLen=28 #specify length of the array job for 02.02_iqtree_array_concat.sh
PROJECT=/data/schwartzlab/Biancani/PlacentalPolytomy
# path to output folder for IQ-TREE
OUTPUT=$PROJECT/output/02_iqtree_assessment
# paths to output directory for 02.02_iqturee_array_concat.sh
# (location of `partitions_` files)
CAT_OUT=$OUTPUT/02.02_concat_trees

cd $CAT_OUT
date

# create directory for analysis files
mkdir -p concat_array_files
mv * concat_array_files/
cd concat_array_files/
> ../combined_iqtree_dLnLs_concat.csv
for f in $(seq 1 ${arrayLen})
do
        cat ${CAT_OUT}/partitions_${f}.txt | while read l
        do
                locname=$(echo ${l} | cut -f2 -d" " | cut -f2- -d_)
                range1=$(echo ${l} | cut -f4 -d" ")
                tree1=$(sed -n 2p ${CAT_OUT}/calcLnL_${f}.sitelh | awk -v a="${range1}" 'BEGIN {split(a, A, /-/)} {x=0;for(i=A[1]+1;i<=A[2]+1;i++)x=x+$i;print x}')
                tree2=$(sed -n 3p ${CAT_OUT}/calcLnL_${f}.sitelh | awk -v a="${range1}" 'BEGIN {split(a, A, /-/)} {x=0;for(i=A[1]+1;i<=A[2]+1;i++)x=x+$i;print x}')
                tree3=$(sed -n 4p ${CAT_OUT}/calcLnL_${f}.sitelh | awk -v a="${range1}" 'BEGIN {split(a, A, /-/)} {x=0;for(i=A[1]+1;i<=A[2]+1;i++)x=x+$i;print x}')
                echo ${locname},${tree1},${tree2},${tree3} >> ../combined_iqtree_dLnLs_concat.csv
        done
done
date
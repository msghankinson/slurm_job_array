#!/bin/sh

#SBATCH -t 2:00:00
#SBATCH -p defq
#SBATCH -N 1
#SBATCH -o jobArrayScript_%A_%a.out
#SBATCH -e jobArrayScript_%A_%a.err
#SBATCH -a 1-3086%1000

line_N=$( awk "NR==$SLURM_ARRAY_TASK_ID" master_example.csv )  # NR means row-# in Awk
shp_filename=$( echo "$line_N" | cut -d "," -f 2 )
lihtc_filename=$( echo "$line_N" | cut -d "," -f 3 )

module load R/4.1.1
module load libudunits2/2.2.28
module load gdal/3.5.0
module load proj/6.3.0
module load geos/3.10.3

Rscript slurm_phase_2.R $shp_filename $lihtc_filename

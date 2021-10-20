#!/bin/bash

# Script to generate the Qiime2 manifest file
# using the files list and their informative CSV (linking SampleID with MaterialId)

# Everything in suffix will be removed from the sample name


echo -e "sample-id,absolute-filepath,direction" > manifest.csv

file_format=$1
forward_suffix=$2
reverse_suffix=$3

if [ ! $1 ] || [ ! $2 ] || [ ! $3 ]
then
    echo "ERROR: missing argument"
    echo "USAGE: $0 file_format forward_suffix reverse_suffix"
    exit 1
fi

if [[ ${file_format:0:1} != "." ]]; 
then 
    echo "ERROR: file format must begin with a ."
    exit 1
fi

#file_format=".fastq.gz"
#forward_suffix="_L001_R1_001.fastq.gz"
#reverse_suffix="_L001_R2_001.fastq.gz"

echo "PROCEEDING..."
samples=$( ls *$file_format | awk -F "$forward_suffix" '{ print $1 }' | awk -F "$reverse_suffix" '{ print $1 }' | sort | uniq )


for i in $samples
do
   echo $i
   file_path_f=$PWD/$i"$forward_suffix""$file_format"
   file_path_r=$PWD/$i"$reverse_suffix""$file_format"
   echo -e "$i,$file_path_f,forward" >> manifest.csv
   echo -e "$i,$file_path_r,reverse" >> manifest.csv
done

tail -n +1 manifest.csv > .manifest_check.temp

while read line
do
    filename=$( echo "line" | awk -F "," '{ print $2 }' )
    if [ ! -e $filename ]
    then
        echo "ERROR: $filename don't exist, there is probably a problem with your suffix choice"
    fi
done<.manifest_check.temp

rm .manifest_check.temp

#sed 's/,/\t/g' manifest.csv > manifest.tsv



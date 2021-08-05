#!/bin/bash

# This Qiime2 step will help to evaluate optimals parameters for the denoising step
# It will generate a serie of denoising on a random subsample (size defined by the user) extracted from the original manifest file

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

if [ $DENOISE_EVALUATION_SAMPLE_SIZE -eq 0 ]
then
    echo "This step cannot be completed with a sample size of 0, you can skip it"
    exit 1
fi

# Make temporary manifest file using defined user sample size
echo "Random Sampling of the manifest file"
head -n 1 $MANIFEST_FILE_PATH > $ANALYSIS_NAME.eval_manifest.temp


if [ "$DATA_TYPE" == "paired" ]
then
    sublist=$( awk 'NR>1' $MANIFEST_FILE_PATH | grep ",forward" | shuf -n $DENOISE_EVALUATION_SAMPLE_SIZE  )
    for i in $sublist
    do
        sample_name=$( echo $i | awk -F ',' '{ print $1 }' )
        echo $sample_name
        grep $sample_name $MANIFEST_FILE_PATH  >> $ANALYSIS_NAME.eval_manifest.temp
    done
else
    awk 'NR>1' $MANIFEST_FILE_PATH | shuf -n $DENOISE_EVALUATION_SAMPLE_SIZE >> $ANALYSIS_NAME.eval_manifest.temp
fi



echo "Importing subsample into qiime2 artifact file"
$SINGULARITY_COMMAND qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path $ANALYSIS_NAME.eval_manifest.temp \
--output-path $ANALYSIS_NAME.denoise_eval_import.qza \
--input-format PairedEndFastqManifestPhred33

echo "Summarizing data import into visualisation file"
$SINGULARITY_COMMAND qiime demux summarize \
--i-data $ANALYSIS_NAME.denoise_eval_import.qza \
--o-visualization $ANALYSIS_NAME.denoise_eval_import.qzv


echo "Preparing to launch tests"
while read line
do
    if [ "${line::1}" == "#" ]
    then
        continue
    fi
    jobn=$( echo $line | awk -F ':' '{ print $1 }' )
    params=$( echo $line | awk -F ':' '{ print $2 }' | sed 's/\r$//' )
    echo "Launching $jobn parameters set"
    $SINGULARITY_COMMAND qiime dada2 denoise-paired --i-demultiplexed-seqs $ANALYSIS_NAME.denoise_eval_import.qza $params --p-n-threads $NB_THREADS --o-table feature-table.$jobn.qza --o-representative-sequences rep-seqs.$jobn.qza --o-denoising-stats stats.$jobn.qza --verbose
    $SINGULARITY_COMMAND qiime metadata tabulate --m-input-file stats.$jobn.qza --o-visualization stats.$jobn.qzv 
    $SINGULARITY_COMMAND qiime tools export --input-path stats.$jobn.qza --output-path stats.$jobn
    mv stats.$jobn/stats.tsv ./stats.$jobn.tsv

done<$TESTFILE_LOCATION

# Manifest file must be done 


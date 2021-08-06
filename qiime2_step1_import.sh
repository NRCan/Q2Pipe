#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile


echo "Importing Data into artifact file"
$SINGULARITY_COMMAND qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path $MANIFEST_FILE_PATH \
--output-path $ANALYSIS_NAME.import.qza \
--input-format PairedEndFastqManifestPhred33

echo "Summarizing Importation into visualisation file"
$SINGULARITY_COMMAND qiime demux summarize \
--i-data $ANALYSIS_NAME.import.qza \
--o-visualization $ANALYSIS_NAME.import.qzv


#qiime cutadapt trim-paired \
#--i-demultiplexed-sequences base_import.qza \
#--o-trimmed-sequences cutadapt.qza \
#--p-front-f GTGYCAGCMGCCGCGGTAA \
#--p-front-r CCGYCAATTYMTTTRAGTTT \
#--p-cores 6

# Manifest file must be done 


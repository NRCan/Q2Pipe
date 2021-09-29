#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#    Step 1 - Importation      #
#       August 18, 2021        #
#                              #
################################

exit_on_error(){
   echo "Qiime2 command error detected"
   echo "Exiting program"
   exit 1
}


optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

if [ $TEMPORARY_DIRECTORY ]
then
    echo "Overriding default temporary directory to $TEMPORARY_DIRECTORY"
    if [ ! -d $TEMPORARY_DIRECTORY ] || [ ! -w $TEMPORARY_DIRECTORY ]
    then
        echo "ERROR: $TEMPORARY_DIRECTORY does not exist or is read only"
        exit 2
    fi
    export TMPDIR=$TEMPORARY_DIRECTORY
fi

echo "Importing Data into artifact file"
$SINGULARITY_COMMAND qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path $MANIFEST_FILE_PATH \
--output-path $ANALYSIS_NAME.import.qza \
--input-format PairedEndFastqManifestPhred33 || exit_on_error

echo "Summarizing Importation into visualisation file"
$SINGULARITY_COMMAND qiime demux summarize \
--i-data $ANALYSIS_NAME.import.qza \
--o-visualization $ANALYSIS_NAME.import.qzv --verbose || exit_on_error



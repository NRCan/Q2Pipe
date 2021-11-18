#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#  Step 3 - Feature Filtering  #
#       October 5, 2021        #
#                              #
################################

exit_on_error(){
   echo "Qiime2 command error detected"
   echo "Exiting program"
   exit 1
}



optionfile=$1

if [ ! $optionfile ] || [ ! -e $optionfile ] || [ ! -r $optionfile ]
then
    echo "ERROR: you must specify a valid, accessible qiime2 optionfile"
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

if [ $p_min_frequency -eq 0 ] && [ $p_min_samples -eq 0 ]
then
    echo "WARNING: both min_frequency and min_samples are equal 0"
    echo "All important files will be copies of original files"
    cp -v $ANALYSIS_NAME.table-dada2.qza $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza
    cp -v $ANALYSIS_NAME.rep-seqs-dada2.qza $ANALYSIS_NAME.rep-seqs-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza

    $SINGULARITY_COMMAND qiime feature-table summarize \
    --i-table $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
    --o-visualization $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qzv \
    --m-sample-metadata-file $METADATA_FILE_PATH --verbose || exit_on_error
    exit 0
fi
    

$SINGULARITY_COMMAND qiime feature-table filter-features \
--i-table $ANALYSIS_NAME.table-dada2.qza \
--p-min-frequency $p_min_frequency \
--p-min-samples $p_min_samples \
--o-filtered-table $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza --verbose || exit_on_error

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--o-visualization $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qzv \
--m-sample-metadata-file $METADATA_FILE_PATH --verbose || exit_on_error

$SINGULARITY_COMMAND qiime feature-table filter-seqs \
--i-data $ANALYSIS_NAME.rep-seqs-dada2.qza \
--i-table $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--o-filtered-data $ANALYSIS_NAME.rep-seqs-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza --verbose || exit_on_error



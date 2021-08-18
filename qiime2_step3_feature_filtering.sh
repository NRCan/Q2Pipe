#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
# Step 3 - Feature Filtering   #
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
if [ -d $TEMPORARY_DIRECTORY ]
then
    echo "Overriding default temporary directory to $TEMPORARY_DIRECTORY"
    export TMPDIR="$TEMPORARY_DIRECTORY"
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



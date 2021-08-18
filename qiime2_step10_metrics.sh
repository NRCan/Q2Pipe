#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
# Step 10 - Metrics Generation #
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


$SINGULARITY_COMMAND qiime diversity core-metrics \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--p-sampling-depth $p_sampling_depth \
--m-metadata-file $METADATA_FILE_PATH \
--output-dir $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity" --verbose || exit_on_error

$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/evenness_vector.qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/evenness-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error

$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/shannon_vector.qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/shannon-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error

$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/observed_features_vector.qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/observed_features-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error

# NOT SURE ABOUT THIS ONE (I-TABLE NOT COPIED INSIDE THE FOLDER)
$SINGULARITY_COMMAND qiime diversity alpha \
--i-table  $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/$ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--p-metric simpson \
--o-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qza --verbose || exit_on_error

$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error




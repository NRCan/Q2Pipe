#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

$SINGULARITY_COMMAND qiime diversity core-metrics \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--p-sampling-depth $p_sampling_depth \
--m-metadata-file $METADATA_FILE_PATH \
--output-dir $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"

$SINGULARITY_COMMAND alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/evenness_vector.qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/evenness-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv

$SINGULARITY_COMMAND alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/shannon_vector.qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/shannon-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv

$SINGULARITY_COMMAND alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/observed_features_vector.qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/observed_features-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv

# NOT SURE ABOUT THIS ONE (I-TABLE NOT COPIED INSIDE THE FOLDER)
$SINGULARITY_COMMAND qiime diversity alpha \
--i-table  $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/$ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--p-metric simpson \
--o-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qza

$SINGULARITY_COMMAND alpha-group-significance \
--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv


# Manifest file must be done 


#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

$SINGULARITY_COMMAND feature-table rarefy \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--p-sampling-depth $p_sampling_depth \
--o-rarefied-table $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qzv

$SINGULARITY_COMMAND qiime taxa barplot \
--i-table $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.barplots_rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qzv


# Manifest file must be done 


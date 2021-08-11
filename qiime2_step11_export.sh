#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

$SINGULARITY_COMMAND qiime tools export \
--input-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--output-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"

biom convert -i $ANALYSIS_NAME.feature-table.biom -o $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".tsv --to-tsv

qiime tools export \
--input-path $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza --output-path $ANALYSIS_NAME.asv_tax_dirrarefied_"$p_sampling_depth"_dn"$p_perc_identity"

# Manifest file must be done 


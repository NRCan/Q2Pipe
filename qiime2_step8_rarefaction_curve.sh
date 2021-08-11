#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

$SINGULARITY_COMMAND alpha-rarefaction \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--p-max-depth $p_max_depth \
--p-steps $p_steps \
--p-iterations $p_iterations \
--p-metrics $p_metrics \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.rarefaction_curves_filtered.qzv 

# Do some things to prepare the curve (maybe show it inside the terminal)

# Manifest file must be done 


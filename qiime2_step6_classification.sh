#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile


if [ ! $CLASSIFIER_DATABASE_PATH ]
then
    classifier_path=$CLASSIFIER_OUTPUT_NAME
else
    classifier_path=$CLASSIFIER_DATABASE_PATH
fi



$SINGULARITY_COMMAND qiime feature-classifier classify-sklearn \
--i-classifier $classifier_path \
--i-reads $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza \
--o-classification $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza

$SINGULARITY_COMMAND qiime metadata tabulate \
--m-input-file $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qzv

$SINGULARITY_COMMAND qiime taxa barplot \
--i-table   $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.barplots_taxo_dn"$p_perc_identity".qzv



# Manifest file must be done 


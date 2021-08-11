#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

if [ "$SKIP_FILTERING" == "true" ]
then
    echo "Skipping option detected, important file will be copy of original files"
    cp -v $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza
    cp -v $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza
    exit 0
fi
$SINGULARITY_COMMAND taxa filter-table \
--i-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--p-exclude $p_exclude \
--o-filtered-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qzv \
--m-sample-metadata-file $METADATA_FILE_PATH

$SINGULARITY_COMMAND qiime taxa filter-seqs \
--i-sequences $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza \
--i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--p-exclude $p_exclude \
--o-filtered-sequences $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza

$SINGULARITY_COMMAND qiime feature-table tabulate-seqs \
--i-data $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qzv

$SINGULARITY_COMMAND qiime taxa barplot \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.filtered_barplots_taxo_dn"$p_perc_identity".qzv


# Manifest file must be done 


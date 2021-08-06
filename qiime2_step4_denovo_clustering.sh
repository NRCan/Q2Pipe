#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile


$SINGULARITY_COMMAND qiime vsearch cluster-features-de-novo \
--i-table $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--i-sequences $ANALYSIS_NAME.rep-seqs-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--p-perc-identity $p_perc_identity \
--o-clustered-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--o-clustered-sequences $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza


# Manifest file must be done 


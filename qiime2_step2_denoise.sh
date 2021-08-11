#!/bin/bash

optionfile=$1

if [ ! $optionfile ]
then
    echo "ERROR: you must specify a qiime2 optionfile"
    exit 1
fi

source $optionfile

ca_flag=""
if [ "$SKIP_CUTADAPT" == "false" ]
then
    ca_flag="_CA"
    untrimmed_flag=""
    if [ "$p_discard_untrimmed" == "true" ]
    then
        untrimmed_flag="--p-discard-untrimmed"
    fi
    echo "Removing Adapters/Primers from reads with CutAdapt"
    $SINGULARITY_COMMAND qiime cutadapt trim-paired \
    --i-demultiplexed-sequences $ANALYSIS_NAME.import.qza  \
    --o-trimmed-sequences $ANALYSIS_NAME.import$ca_flag.qza  \
    $forward_trim_param $forward_primer \
    $reverse_trim_param $reverse_primer \
    $untrimmed_flag --p-cores $NB_THREADS

    echo "Summarizing Cutadapt trimming into visualisation file"
    $SINGULARITY_COMMAND qiime demux summarize \
    --i-data $ANALYSIS_NAME.import$ca_flag.qza \
    --o-visualization $ANALYSIS_NAME.import$ca_flag.qzv
fi



$SINGULARITY_COMMAND qiime dada2 denoise-paired \
--i-demultiplexed-seqs $ANALYSIS_NAME.import$ca_flag.qza \
--o-table $ANALYSIS_NAME.table-dada2.qza \
--o-representative-sequences $ANALYSIS_NAME.rep-seqs-dada2.qza \
--o-denoising-stats $ANALYSIS_NAME.denoising-stats-dada2.qza \
--p-trim-left-f $p_trim_left_f \
--p-trim-left-r $p_trim_left_r \
--p-trunc-len-f $p_trunc_len_f \
--p-trunc-len-r $p_trunc_len_r \
--p-max-ee-f $p_max_ee_f \
--p-max-ee-r $p_max_ee_r \
--p-n-threads $NB_THREADS \
--p-n-reads-learn $p_n_reads_learn \
--p-chimera-method $p_chimera_method \
--p-min-fold-parent-over-abundance $p_min_fold_parent_over_abundance

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2.qza \
--o-visualization $ANALYSIS_NAME.table-dada2.qzv



# Manifest file must be done 


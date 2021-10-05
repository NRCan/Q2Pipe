#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#     Step 2 - Denoising       #
#       October 5, 2021        #
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

if [ $TEMPORARY_DIRECTORY ]
then
    echo "Overriding default temporary directory to $TEMPORARY_DIRECTORY"
    if [ ! -d $TEMPORARY_DIRECTORY ] || [ ! -w $TEMPORARY_DIRECTORY ]
    then
        echo "ERROR: $TEMPORARY_DIRECTORY does not exist or is read only"
        exit 2
    fi
    export TMPDIR=$TEMPORARY_DIRECTORY
fi

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
    $untrimmed_flag --p-cores $NB_THREADS --verbose || exit_on_error

    echo "Summarizing Cutadapt trimming into visualisation file"
    $SINGULARITY_COMMAND qiime demux summarize \
    --i-data $ANALYSIS_NAME.import$ca_flag.qza \
    --o-visualization $ANALYSIS_NAME.import$ca_flag.qzv --verbose
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
--p-min-fold-parent-over-abundance $p_min_fold_parent_over_abundance --verbose || exit_on_error

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2.qza \
--o-visualization $ANALYSIS_NAME.table-dada2.qzv --verbose


echo "Extracting Mean sample frequency"
$SINGULARITY_COMMAND qiime tools export --input-path $ANALYSIS_NAME.table-dada2.qzv --output-path $ANALYSIS_NAME.temporary_export_dada2table


mean_line=$( grep -n "Mean frequency" $ANALYSIS_NAME.temporary_export_dada2table/index.html | head -n 1 | cut -f1 -d: )
let $[ mean_line += 1 ]

freq=$( head -n $mean_line $ANALYSIS_NAME.temporary_export_dada2table/index.html | tail -n 1 | sed 's/ //g' | sed 's/<td>//g' | sed 's;</td>;;g' )

echo ""
echo "Mean frequency: $freq"
rm -rf $ANALYSIS_NAME.temporary_export_dada2table



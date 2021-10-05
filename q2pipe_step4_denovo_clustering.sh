#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#  Step 4 - Denovo_Clustering  #
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

$SINGULARITY_COMMAND qiime vsearch cluster-features-de-novo \
--i-table $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--i-sequences $ANALYSIS_NAME.rep-seqs-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--p-perc-identity $p_perc_identity \
--o-clustered-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--o-clustered-sequences $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza --verbose || exit_on_error

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qzv --verbose




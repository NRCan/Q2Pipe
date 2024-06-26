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

if [ ! $optionfile ] || [ ! -e $optionfile ] || [ ! -r $optionfile ]
then
    echo "ERROR: you must specify a valid, accessible qiime2 optionfile"
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

if [ ! $TMPDIR ]
then
    export TMPDIR=/tmp
fi

if [ "$APPTAINER_COMMAND" != "" ]
then
    echo "DEBUG: Checking temporary folder"
    temp_check=$( $APPTAINER_COMMAND mktemp -t Q2PIPE_TEMPFOLDER_CHECK.XXXXXX.temp  )
    bname=$( basename $temp_check )
    if [ ! -e $TMPDIR/$bname ]
    then
        echo "ERROR: Disparity between Apptainer temporary folder and system temporary folder"
        echo "Please make sure both are pointing to the same folder"
        exit 5
    else
        echo "DEBUG: Temporary file check status: OK"
        rm $TMPDIR/Q2PIPE_TEMPFOLDER_CHECK.??????.temp
    fi
fi

if [ "$p_perc_identity" == "NA" ]
then
    echo "NA parameter detected, creating necessary files to skip clustering"
    cp -v $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza
    cp -v $ANALYSIS_NAME.rep-seqs-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza
    exit 0
fi

$APPTAINER_COMMAND qiime vsearch cluster-features-de-novo \
--i-table $ANALYSIS_NAME.table-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--i-sequences $ANALYSIS_NAME.rep-seqs-dada2_minfreq"$p_min_frequency"_minsamp"$p_min_samples".qza \
--p-perc-identity $p_perc_identity \
--p-threads $NB_THREADS \
--o-clustered-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--o-clustered-sequences $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza --verbose || exit_on_error

$APPTAINER_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qzv --verbose

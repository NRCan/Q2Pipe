#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
# Step 5 - Classifier Training #
#       October 5, 2021        #
#                              #
################################

echo "WARNING: STEP DEPRECATED IN VERSION Q2PIPE V0.93"
echo "THIS STEP WILL BE COMPLETELY REMOVED IN Q2PIPE V0.94"

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

if [ $CLASSIFIER_DATABASE_PATH ]
then
    echo "WARNING: CLASSIFIER_DATABASE_PATH specified in optionfile"
    echo "This step must be skipped if you already have a trained database"
    exit 0
fi


#fasta_name=$( echo $FASTA_DATABASE_PATH | sed 's/\.[^.]*$//' )
#tax_name=$( echo $TAXO_DATABASE_PATH | sed 's/\.[^.]*$//' )

#$APPTAINER_COMMAND qiime tools import \
# --type FeatureData[Sequence] \
# --input-path $FASTA_DATABASE_PATH \
# --output-path $ANALYSIS_NAME.$fasta_name.qza

#$APPTAINER_COMMAND qiime tools import \
# --type FeatureData[Taxonomy] \
# --input-path $TAXO_DATABASE_PATH \
# --output-path $ANALYSIS_NAME.$tax_name.qza \
# --input-format HeaderlessTSVTaxonomyFormat

#$APPTAINER_COMMAND qiime feature-classifier fit-classifier-naive-bayes \
# --i-reference-reads $ANALYSIS_NAME.$fasta_name.qza \
# --i-reference-taxonomy $ANALYSIS_NAME.$tax_name.qza \
# --o-classifier $CLASSIFIER_OUTPUT_NAME

$APPTAINER_COMMAND qiime feature-classifier fit-classifier-naive-bayes \
 --i-reference-reads $SEQS_QZA_PATH \
 --i-reference-taxonomy $TAXO_QZA_PATH \
 --o-classifier $CLASSIFIER_OUTPUT_NAME --verbose || exit_on_error



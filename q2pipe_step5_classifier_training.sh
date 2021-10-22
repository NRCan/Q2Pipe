#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
# Step 5 - Classifier Training #
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

if [ $CLASSIFIER_DATABASE_PATH ]
then
    echo "WARNING: CLASSIFIER_DATABASE_PATH specified in optionfile"
    echo "This step must be skipped if you already have a trained database"
    exit 0
fi


#fasta_name=$( echo $FASTA_DATABASE_PATH | sed 's/\.[^.]*$//' )
#tax_name=$( echo $TAXO_DATABASE_PATH | sed 's/\.[^.]*$//' )

#$SINGULARITY_COMMAND qiime tools import \
# --type FeatureData[Sequence] \
# --input-path $FASTA_DATABASE_PATH \
# --output-path $ANALYSIS_NAME.$fasta_name.qza

#$SINGULARITY_COMMAND qiime tools import \
# --type FeatureData[Taxonomy] \
# --input-path $TAXO_DATABASE_PATH \
# --output-path $ANALYSIS_NAME.$tax_name.qza \
# --input-format HeaderlessTSVTaxonomyFormat

#$SINGULARITY_COMMAND qiime feature-classifier fit-classifier-naive-bayes \
# --i-reference-reads $ANALYSIS_NAME.$fasta_name.qza \
# --i-reference-taxonomy $ANALYSIS_NAME.$tax_name.qza \
# --o-classifier $CLASSIFIER_OUTPUT_NAME

$SINGULARITY_COMMAND qiime feature-classifier fit-classifier-naive-bayes \
 --i-reference-reads $SEQS_QZA_PATH \
 --i-reference-taxonomy $TAXO_QZA_PATH \
 --o-classifier $CLASSIFIER_OUTPUT_NAME --verbose || exit_on_error



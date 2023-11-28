#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#   Step 6 - Classification    #
#      November 28, 2023       #
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
if [ $CLASSIFIER_DATABASE_PATH ] && [ $CLASSIFIER_OUTPUT_NAME ]
then
    if [ "$(stat -L -c %d:%i $CLASSIFIER_DATABASE_PATH)" = "$(stat -L -c %d:%i $CLASSIFIER_OUTPUT_NAME)" ] 
    then
        classifier_path=$CLASSIFIER_DATABASE_PATH
    else
        echo "ERROR: Ambiguity detected in option file" 
        echo "CLASSIFIER_DATABASE_PATH and CLASSIFIER_OUTPUT_NAME are both defined but are not the same file"
        exit 1
    fi
fi

if [ ! $CLASSIFIER_DATABASE_PATH ]
then
    classifier_path=$CLASSIFIER_OUTPUT_NAME
else
    classifier_path=$CLASSIFIER_DATABASE_PATH
fi


if [ ! $CLASSIFIER_NB_THREADS ]
then
    echo "WARNING: CLASSIFIER_NB_THREADS variable not set, will fallback on NB_THREADS"
    echo "This could cause a RAM overload during the classification"
    CLASSIFIER_NB_THREADS=$NB_THREADS
fi


$APPTAINER_COMMAND qiime feature-classifier classify-sklearn \
--i-classifier $classifier_path \
--i-reads $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza \
--p-n-jobs $CLASSIFIER_NB_THREADS \
--p-confidence $p_confidence \
--o-classification $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza --verbose || exit_on_error

$APPTAINER_COMMAND qiime metadata tabulate \
--m-input-file $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qzv --verbose

$APPTAINER_COMMAND qiime taxa barplot \
--i-table   $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
--i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.barplots_taxo_dn"$p_perc_identity".qzv --verbose || exit_on_error

#if [ "$SKIP_FILTERING" == "true" ]
#then
#    echo "Filtering skip option detected, table-dada2 and rep-seqs will copied as filtered_table for filename coherency"
#    cp -v $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza
#    cp -v $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza
#fi




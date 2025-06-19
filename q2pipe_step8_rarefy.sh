#!/bin/bash
################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#      Step 8 - Rarefy         #
#       June 19, 2025          #
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

if [ "$SKIP_RAREFACTION" == "true" ]
then
    echo "Rarefaction override detected in option file, you must skip this step"
    exit 0
fi

# Add rarefaction/normalization tag here (rarefied or normalized)
# This tag must follow in all scripts.

if [ "$RAREFACTION_METHOD" == "rarefaction" ]
then
    rarefy_tag="rarefied" 

    $APPTAINER_COMMAND qiime feature-table rarefy \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --p-sampling-depth $p_sampling_depth \
    --p-random-seed $p_random_seed \
    --o-rarefied-table $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza --verbose || exit_on_error

elif [ "$RAREFACTION_METHOD" == "normalization" ]
then
    rarefy_tag="normalized"

    $APPTAINER_COMMAND qiime srs SRS \
    --i-table MISA_ITS_mai2024.filtered_table_dnNA.qza \
    --p-seed $p_random_seed \
    --p-c-min $p_sampling_depth \
    --o-normalized-table $ANALYSIS_NAME.normalized_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza --verbose || exit_on_error

else
    echo "ERROR: RAREFACTION_METHOD is not set to a valid value (rarefaction or normalization)"
    exit 1
fi

$APPTAINER_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME."$rarefy_tag"_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--o-visualization $ANALYSIS_NAME."$rarefy_tag"_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qzv --verbose

$APPTAINER_COMMAND qiime taxa barplot \
--i-table $ANALYSIS_NAME."$rarefy_tag"_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.barplots_"$rarefy_tag"_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qzv --verbose || exit_on_error




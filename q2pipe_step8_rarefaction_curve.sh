#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#  Step 8 - Rarefaction Curve  #
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

if [ "$SKIP_RAREFACTION" == "true" ]
then
    echo "Rarefaction override detected in option file, you must skip this step"
    exit 0
fi

metric_str=''

if [ $p_metrics ]
then
    metric_str=""
    for i in $( echo $p_metrics | sed 's/,/ /g' ) 
    do  
        metric_str="$metric_str --p-metrics $i"
    done
    #metric_str="$metric_str \\"
fi


$APPTAINER_COMMAND qiime diversity alpha-rarefaction \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--p-max-depth $p_max_depth \
--p-steps $p_steps \
--p-iterations $p_iterations $metric_str \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.rarefaction_curves_filtered.qzv --verbose || exit_on_error

if [ "$GENERATE_PHYLOGENY" == "true" ]
then
    $APPTAINER_COMMAND qiime diversity alpha-rarefaction \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --i-phylogeny $ANALYSIS_NAME.rooted_tree.qza \
    --p-max-depth $p_max_depth \
    --p-steps $p_steps \
    --p-iterations $p_iterations $metric_str \
    --m-metadata-file $METADATA_FILE_PATH \
    --o-visualization $ANALYSIS_NAME.rarefaction_curves_filtered_phylo.qzv --verbose || exit_on_error
fi

# Do some things to prepare the curve (maybe show it inside the terminal)



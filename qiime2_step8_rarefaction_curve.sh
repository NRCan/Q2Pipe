#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
# Step 8 - Rarefaction Curve   #
#       August 18, 2021        #
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

#echo "WARNING, default system temp directory will be used for this command (unresolved issue with user defined folders)"
# Temporary fix, because user defined temporary folder cause an Permission Denied error in Python
# Must post this on Qiime2 github
#if [ -d $TEMPORARY_DIRECTORY ]
#then
#    echo "Overriding default temporary directory to $TEMPORARY_DIRECTORY"
#    export TMPDIR="$TEMPORARY_DIRECTORY"
#fi


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


$SINGULARITY_COMMAND qiime diversity alpha-rarefaction \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--p-max-depth $p_max_depth \
--p-steps $p_steps \
--p-iterations $p_iterations $metric_str \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.rarefaction_curves_filtered.qzv --verbose || exit_on_error

# Do some things to prepare the curve (maybe show it inside the terminal)



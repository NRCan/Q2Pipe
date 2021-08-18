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

if [ -d $TEMPORARY_DIRECTORY ]
then
    echo "Overriding default temporary directory to $TEMPORARY_DIRECTORY"
    export TMPDIR="$TEMPORARY_DIRECTORY"
fi

$SINGULARITY_COMMAND qiime diversity alpha-rarefaction \
--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
--p-max-depth $p_max_depth \
--p-steps $p_steps \
--p-iterations $p_iterations \
--p-metrics $p_metrics \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.rarefaction_curves_filtered.qzv --verbose || exit_on_error

# Do some things to prepare the curve (maybe show it inside the terminal)



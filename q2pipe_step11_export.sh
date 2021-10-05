#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#    Step 11 - Exportation     #
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

if [ "$SKIP_RAREFACTION" == "true" ]
then
    $SINGULARITY_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity"

    $SINGULARITY_COMMAND biom convert -i $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity"/feature-table.biom -o $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".tsv --to-tsv

    $SINGULARITY_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"
else
    $SINGULARITY_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"

    $SINGULARITY_COMMAND biom convert -i $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"/feature-table.biom -o $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".tsv --to-tsv

    $SINGULARITY_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"
fi


#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#    Step 1 - Importation      #
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

$SINGULARITY_COMMAND qiime tools export \
--input-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
--output-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"

biom convert -i $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"/feature-table.biom -o $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".tsv --to-tsv

qiime tools export \
--input-path $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
--output-path $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"



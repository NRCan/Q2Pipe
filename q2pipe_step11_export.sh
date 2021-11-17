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

if  [ "$GENERATE_ANCOM" == "true" ] && [ ! $m_metadata_column ]
then
    echo "ERROR: m_metadata_column not set in the option file"
    echo "This parameter is mandatory for ANCOM analysis"
    exit 3
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

# Feature in developpement
if [ "$GENERATE_ANCOM" == "true" ]
then
    echo "Preparing ANCOM analysis"
    if [ ! -d "$ANALYSIS_NAME"_ANCOM ]
    then
        mkdir "$ANALYSIS_NAME"_ANCOM 
    fi

    $SINGULARITY_COMMAND qiime taxa collapse \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --p-level $p_level \
    --o-collapsed-table "$ANALYSIS_NAME"_ANCOM/feature_table_ANCOM.qza

    $SINGULARITY_COMMAND qiime composition add-pseudocount \
    --i-table "$ANALYSIS_NAME"_ANCOM/feature_table_ANCOM.qza \
    --o-composition-table "$ANALYSIS_NAME"_ANCOM/composition_table_ANCOM.qza

    m_metadata_column=$( echo $m_metadata_column | sed 's/,/ /g' )
    
    for col in $m_metadata_column
    do
        echo "Generating ANCOM for column $col"
        $SINGULARITY_COMMAND qiime composition ancom  \
        --i-table "$ANALYSIS_NAME"_ANCOM/composition_table_ANCOM.qza \
        --m-metadata-file $METADATA_FILE_PATH \
        --m-metadata-column $col \
        --o-visualization "$ANALYSIS_NAME"_ANCOM/ANCOM_"$col"_results.qzv
    done

fi

#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#   Step 8 - Taxa Filtering    #
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

metatag="metafiltered_"
if [ ! $p_where ] || [ "$p_where" == "" ]
then
    echo "No metadata filtering parameter detected... skipping"
    metatag=""
else
    echo "Applying metadata filtering..."
    $SINGULARITY_COMMAND qiime feature-table filter-samples \
    --i-table $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza \
    --m-metadata-file $METADATA_FILE_PATH \
    --p-where $p_where \
    --o-filtered-table $ANALYSIS_NAME."$metatag"table-dada2_dn"$p_perc_identity".qza || exit_on_error

    $SINGULARITY_COMMAND qiime feature-table summarize \
    --i-table $ANALYSIS_NAME."$metatag"table-dada2_dn"$p_perc_identity".qza \
    --o-visualization $ANALYSIS_NAME."$metatag"table-dada2_dn"$p_perc_identity".qzv \
    --m-sample-metadata-file $METADATA_FILE_PATH || exit_on_error

    $SINGULARITY_COMMAND qiime feature-table filter-seqs \
    --i-data $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza \
    --i-table $ANALYSIS_NAME."$metatag"table-dada2_dn"$p_perc_identity".qza \
    --o-filtered-data $ANALYSIS_NAME."$metatag"rep-seqs-dada2_dn"$p_perc_identity".qza || exit_on_error

    $SINGULARITY_COMMAND qiime taxa barplot \
    --i-table $ANALYSIS_NAME."$metatag"table-dada2_dn"$p_perc_identity".qza \
    --i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --m-metadata-file $METADATA_FILE_PATH \
    --o-visualization $ANALYSIS_NAME."$metatag"barplots_taxo_dn"$p_perc_identity".qzv || exit_on_error
fi

#if [ "$SKIP_FILTERING" == "true" ]
#then
#    echo "Skip filtering option detected, you must skip this step"
#    #cp -v $ANALYSIS_NAME.table-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza
#    #cp -v $ANALYSIS_NAME.rep-seqs-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza
#    exit 0
#fi

taxa_filt=1
if [ ! $p_exclude ] && [ ! $p_include ]
then
    echo "Both p_include and p_exclude are undefined, Taxa filtering will be skipped"
    echo "table-dada2 and rep-seqs will copied as filtered_table for filename coherency"
    cp -v $ANALYSIS_NAME."$metatag"table-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza
    cp -v $ANALYSIS_NAME."$metatag"rep-seqs-dada2_dn"$p_perc_identity".qza $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza
    taxa_filt=0
fi




if [ $taxa_filt -eq 1 ]
then
    if [ $p_exclude ]
    then
        excl_param="--p-exclude $p_exclude"
    fi

    if [ $p_include ]
    then
        excl_param="--p-include $p_include"
    fi

    if [ $p_exclude ] && [ $p_include ]
    then
        excl_param="--p-include $p_include --p-exclude $p_exclude"
    fi

    echo "Applying Taxa filtering..."
    $SINGULARITY_COMMAND qiime taxa filter-table \
    --i-table $ANALYSIS_NAME."$metatag"table-dada2_dn"$p_perc_identity".qza \
    --i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    $excl_param \
    --p-mode $p_mode \
    --o-filtered-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza --verbose || exit_on_error

    $SINGULARITY_COMMAND qiime feature-table summarize \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --o-visualization $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qzv --verbose \
    --m-sample-metadata-file $METADATA_FILE_PATH

    $SINGULARITY_COMMAND qiime taxa filter-seqs \
    --i-sequences $ANALYSIS_NAME."$metatag"rep-seqs-dada2_dn"$p_perc_identity".qza \
    --i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    $excl_param \
    --p-mode $p_mode \
    --o-filtered-sequences $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza --verbose || exit_on_error

    $SINGULARITY_COMMAND qiime feature-table tabulate-seqs \
    --i-data $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza \
    --o-visualization $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qzv --verbose

    $SINGULARITY_COMMAND qiime taxa barplot \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --m-metadata-file $METADATA_FILE_PATH \
    --o-visualization $ANALYSIS_NAME.filtered_barplots_taxo_dn"$p_perc_identity".qzv --verbose || exit_on_error
fi

if [ "$GENERATE_PHYLOGENY" == "true" ]
then
    echo "Generating phylogenetic trees"
    $SINGULARITY_COMMAND qiime phylogeny align-to-tree-mafft-fasttree \
    --p-n-threads $NB_THREADS \
    --i-sequences $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza \
    --o-alignment $ANALYSIS_NAME.filtered_aligned_rep-seqs-dada2_dn"$p_perc_identity".qza \
    --o-masked-alignment $ANALYSIS_NAME.filtered_masked_aligned_rep-seqs-dada2_dn"$p_perc_identity".qza \
    --o-tree $ANALYSIS_NAME.unrooted_tree.qza \
    --o-rooted-tree $ANALYSIS_NAME.rooted_tree.qza
fi

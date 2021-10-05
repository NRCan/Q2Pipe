#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
# Step 10 - Metrics Generation #
#    No rarefaction version    #
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

if [ "$SKIP_RAREFACTION" == "false" ]
then
    echo "ERROR: Rarefaction override not detected in option file, you must use qiime2_step10_metrics"
    exit 1
fi


#if [ -d $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity" ]
#then
#    echo "ERROR: Folder \"$ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"\" already exist"
#    echo "Please delete this folder before proceeding"
#    exit 1
#fi

if [ "$SKIP_RAREFACTION" == "true" ] && [ -d "$ANALYSIS_NAME".metrics_norarefaction_dn"$p_perc_identity" ]
then
    echo "ERROR: Folder $ANALYSIS_NAME.metrics_norarefaction_dn$p_perc_identity already exist"
    echo "Please delete this folder before proceeding"
    exit 1
fi

output_f="$ANALYSIS_NAME.metrics_norarefaction_dn$p_perc_identity"
mkdir $output_f

# Could be added as an option
alpha_metrics="shannon simpson observed_features chao1 pielou_e"
beta_metrics="braycurtis jaccard"

for i in $alpha_metrics
do
    echo "Calculating alpha diversity metric $i"
    $SINGULARITY_COMMAND qiime diversity alpha \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --p-metric $i \
    --o-alpha-diversity $output_f/alpha_$i.qza

    $SINGULARITY_COMMAND qiime diversity alpha-group-significance \
    --i-alpha-diversity $output_f/alpha_$i.qza \
    --m-metadata-file $METADATA_FILE_PATH \
    --o-visualization $output_f/alpha_$i.qzv
done

for i in $beta_metrics
do
    echo "Calculating beta diversity metric $i"
    $SINGULARITY_COMMAND qiime diversity beta \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --p-metric $i \
    --p-n-jobs $NB_THREADS \
    --o-distance-matrix $output_f/beta_"$i"_distance_matrix.qza

    $SINGULARITY_COMMAND qiime diversity pcoa \
    --i-distance-matrix $output_f/beta_"$i"_distance_matrix.qza \
    --o-pcoa $output_f/beta_"$i"_pcoa.qza

    $SINGULARITY_COMMAND qiime emperor plot \
    --i-pcoa $output_f/beta_"$i"_pcoa.qza \
    --m-metadata-file $METADATA_FILE_PATH \
    --o-visualization $output_f/beta_"$i"_emperor.qzv

done

# Alpha Diversity $SINGULARITY_COMMAND qiime diversity alpha \ --i-table 
#$ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \ --p-metric shannon \ --o-alpha-diversity 
#$output_f/alpha_shannon.qza

#qiime diversity alpha-group-significance \
#--i-alpha-diversity $output_f/alpha_shannon.qza \
#--m-metadata-file $METADATA_FILE_PATH \
#--o-visualization $output_f/alpha_shannon.qzv

#$SINGULARITY_COMMAND qiime tools export \
#--input-path  $output_f/alpha_shannon.qza \
#--output-path $output_f/alpha_shannon.txt

#$SINGULARITY_COMMAND qiime diversity alpha \
#--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
#--p-metric pielou_e \
#--o-alpha-diversity $output_f/alpha_pielou.qza

#$SINGULARITY_COMMAND qiime tools export \
#--input-path $output_f/alpha_pielou.qza \
#--output-path $output_f/alpha_pielou.txt

#$SINGULARITY_COMMAND qiime diversity alpha \
#--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
#--p-metric observed_features \
#--o-alpha-diversity $output_f/alpha_observedFeatures.qza

#$SINGULARITY_COMMAND qiime tools export \
#--input-path $output_f/alpha_observedFeatures.qza \
#--output-path $output_f/alpha_observedFeatures.txt

# Beta Diversity
#$SINGULARITY_COMMAND qiime diversity beta \
#--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
#--p-metric jaccard \
#--p-n-jobs $NB_THREADS \
#--o-distance-matrix $output_f/distance-matrix_jaccard.qza

#$SINGULARITY_COMMAND qiime diversity pcoa \
#--i-distance-matrix $output_f/distance-matrix_jaccard.qza \
#--o-pcoa $output_f/pcoa_jaccard.qza

#$SINGULARITY_COMMAND qiime emperor plot \
#--i-pcoa $output_f/pcoa_jaccard.qza \
#--m-metadata-file $METADATA_FILE_PATH \
#--o-visualization $output_f/pcoa_jaccard.qzv

#$SINGULARITY_COMMAND qiime diversity core-metrics \
#--i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
#--p-sampling-depth $p_sampling_depth \
#--m-metadata-file $METADATA_FILE_PATH \
#--output-dir $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity" --verbose || exit_on_error

#$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
#--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/evenness_vector.qza \
#--m-metadata-file $METADATA_FILE_PATH \
#--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/evenness-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error

#$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
#--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/shannon_vector.qza \
#--m-metadata-file $METADATA_FILE_PATH \
#--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/shannon-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error

#$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
#--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/observed_features_vector.qza \
#--m-metadata-file $METADATA_FILE_PATH \
#--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/observed_features-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error

#$SINGULARITY_COMMAND qiime diversity alpha \
#--i-table  $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
#--p-metric simpson \
#--o-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qza --verbose || exit_on_error

#$SINGULARITY_COMMAND qiime diversity alpha-group-significance \
#--i-alpha-diversity $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qza \
#--m-metadata-file $METADATA_FILE_PATH \
#--o-visualization $ANALYSIS_NAME.core-metrics-results-rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/simpson_index-group-significance_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".qzv --verbose || exit_on_error




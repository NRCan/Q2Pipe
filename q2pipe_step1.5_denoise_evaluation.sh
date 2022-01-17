#!/bin/bash

#################################
#                               #
#       Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)   #
# Step 1.5 - Denoise Evaluation #
#        October 5, 2021        #
#                               #
#################################

exit_on_error(){
   echo "Qiime2 command error detected"
   echo "Exiting program"
   exit 1
}




# This Qiime2 step will help to evaluate optimals parameters for the denoising step
# It will generate a serie of denoising on a random subsample (size defined by the user) extracted from the original manifest file

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

if [ ! $TESTFILE_PATH ] || [ ! -e $TESTFILE_PATH ] || [ ! -r $TESTFILE_PATH ]
then
    echo "ERROR: you must specify a valid, accessible testfile in the optionfile"
    exit 1
fi

if [ $DENOISE_EVALUATION_SAMPLE_SIZE -eq 0 ]
then
    echo "This step cannot be completed with a sample size of 0, you can skip it"
    exit 1
fi


if [ "$FORCE_RESAMPLING" == "true" ] || [ ! -e $ANALYSIS_NAME.eval_manifest.temp ]
then
    # Make temporary manifest file using defined user sample size
    echo "Random Sampling of the manifest file"
    head -n 1 $MANIFEST_FILE_PATH > $ANALYSIS_NAME.eval_manifest.temp


    if [ "$DATA_TYPE" == "paired" ]
    then
        sublist=$( awk 'NR>1' $MANIFEST_FILE_PATH | grep ",forward" | shuf -n $DENOISE_EVALUATION_SAMPLE_SIZE  )
        for i in $sublist
        do
            sample_name=$( echo $i | awk -F ',' '{ print $1 }' )
            echo $sample_name
            grep $sample_name $MANIFEST_FILE_PATH  >> $ANALYSIS_NAME.eval_manifest.temp
        done
    else
        awk 'NR>1' $MANIFEST_FILE_PATH | shuf -n $DENOISE_EVALUATION_SAMPLE_SIZE >> $ANALYSIS_NAME.eval_manifest.temp
    fi
else
    echo "Random manifest already present, skipping sampling"
fi

if [ "$DRY_RUN" == "true" ]
then
    echo "Dry run mode detected, ending program"
    exit 0
fi

echo "Importing subsample into qiime2 artifact file"
$SINGULARITY_COMMAND qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path $ANALYSIS_NAME.eval_manifest.temp \
--output-path $ANALYSIS_NAME.denoise_eval_import.qza \
--input-format PairedEndFastqManifestPhred33 || exit_on_error

echo "Summarizing data import into visualisation file"
$SINGULARITY_COMMAND qiime demux summarize \
--i-data $ANALYSIS_NAME.denoise_eval_import.qza \
--o-visualization $ANALYSIS_NAME.denoise_eval_import.qzv --verbose

ca_flag=""
if [ "$SKIP_CUTADAPT" == "false" ]
then
    ca_flag="_CA"
    untrimmed_flag=""
    if [ "$p_discard_untrimmed" == "true" ]
    then
        untrimmed_flag="--p-discard-untrimmed"
    fi
    echo "Removing Adapters/Primers from reads with CutAdapt"
    $SINGULARITY_COMMAND qiime cutadapt trim-paired \
    --i-demultiplexed-sequences $ANALYSIS_NAME.denoise_eval_import.qza \
    --o-trimmed-sequences $ANALYSIS_NAME.denoise_eval_import$ca_flag.qza \
    --p-match-adapter-wildcards \
    $forward_trim_param $forward_primer \
    $reverse_trim_param $reverse_primer \
    $untrimmed_flag --p-cores $NB_THREADS --verbose || exit_on_error

    echo "Summarizing Cutadapt trimming into visualisation file"
    $SINGULARITY_COMMAND qiime demux summarize \
    --i-data $ANALYSIS_NAME.denoise_eval_import$ca_flag.qza \
    --o-visualization $ANALYSIS_NAME.denoise_eval_import$ca_flag.qzv --verbose

fi


if [ ! -d "$ANALYSIS_NAME"_DenoiseTest_Results ]
then
    mkdir "$ANALYSIS_NAME"_DenoiseTest_Results
fi
echo "Preparing to launch tests"
while read line
do
    if [ "${line::1}" == "#" ] || [ -z "$line" ]
    then
        continue
    fi
    jobn=$( echo $line | awk -F ':' '{ print $1 }' )
    params=$( echo $line | awk -F ':' '{ print $2 }' | sed 's/\r$//' )
    echo "Launching $jobn parameters set"
    $SINGULARITY_COMMAND qiime dada2 denoise-paired --i-demultiplexed-seqs $ANALYSIS_NAME.denoise_eval_import$ca_flag.qza $params --p-n-threads $NB_THREADS --o-table $ANALYSIS_NAME.feature-table.$jobn.qza --o-representative-sequences $ANALYSIS_NAME.rep-seqs.$jobn.qza --o-denoising-stats $ANALYSIS_NAME.stats.$jobn.qza --verbose
    if [ $? -ne 0 ]
    then
        echo "Command error detected during test denoising, $jobn will be skipped"
        continue
    fi
    $SINGULARITY_COMMAND qiime feature-table summarize --i-table $ANALYSIS_NAME.feature-table.$jobn.qza  --o-visualization $ANALYSIS_NAME.feature-table.$jobn.qzv
    $SINGULARITY_COMMAND qiime metadata tabulate --m-input-file $ANALYSIS_NAME.stats.$jobn.qza --o-visualization $ANALYSIS_NAME.stats.$jobn.qzv --verbose
    $SINGULARITY_COMMAND  qiime feature-table tabulate-seqs --i-data $ANALYSIS_NAME.rep-seqs.$jobn.qza --o-visualization $ANALYSIS_NAME.rep-seqs.$jobn.qzv
    # Export results in TSV format (easier for downstream analysis)
    $SINGULARITY_COMMAND qiime tools export --input-path $ANALYSIS_NAME.stats.$jobn.qza --output-path $ANALYSIS_NAME.stats.$jobn
    mv $ANALYSIS_NAME.stats.$jobn/stats.tsv ./$ANALYSIS_NAME.stats.$jobn.tsv
    rm -rf $ANALYSIS_NAME.stats.$jobn

    echo "Moving $jobn results to "$ANALYSIS_NAME"_DenoiseTest_Results"
    mv $ANALYSIS_NAME.*.$jobn.* "$ANALYSIS_NAME"_DenoiseTest_Results/

done<$TESTFILE_PATH


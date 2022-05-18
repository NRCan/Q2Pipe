#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#  By: Patrick Gagne (NRCan)   #
#    Step 1 - Importation      #
#        May 16, 2022          #
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

manifest_list=$( echo $MANIFEST_FILE_PATH | sed 's/,/ /g' )

echo "Creating run folder"
for manifest in $manifest_list
do
    manifest_name=$( basename $manifest |  sed 's/\.[^.]*$//' )
    if [ -d $manifest_name ]
    then
        echo "$manifest_name folder found... checking content"
        if [ -e $manifest_name/$manifest_name.import.qza ]
        then
            echo "QZA file found, skipping run..."
            continue
        else
            echo "QZA not found, proceeding with import"
        fi
    else
        mkdir $manifest_name
    fi

    echo "Importing $manifest_name Data into artifact file"
    $SINGULARITY_COMMAND qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path $manifest \
    --output-path $manifest_name/$manifest_name.import.qza \
    --input-format PairedEndFastqManifestPhred33 || exit_on_error

    echo "Summarizing $manifest_name importation into visualisation file"
    $SINGULARITY_COMMAND qiime demux summarize \
    --i-data $manifest_name/$manifest_name.import.qza \
    --o-visualization $manifest_name/$manifest_name.import.qzv --verbose || exit_on_error
done

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
for manifest in $manifest_list
do
   if [ ! -e $manifest ]
   then
       echo "ERROR: $manifest not found"
       exit 1
   fi
done


# Sample duplicate checking #
sampleline=$(( $( cat $manifest_list | uniq | wc -l ) - $( echo $manifest_list | wc -w ) ))
uniqline=$(( $( cat $manifest_list | sort | uniq | wc -l ) -1 ))
#echo $sampleline
#echo $uniqline

if [ $sampleline -ne $uniqline ]
then
    echo ""
    echo "ERROR: some samples are present in more then one manifest"
    echo ""
    offendingl=$( cat $manifest_list | sort | uniq -d | grep -v "sample-id,absolute-filepath,direction" )
    echo "Offending lines:"
    for i in $offendingl
    do
        grep $i $manifest_list
    done
    exit 1
fi


tempcheck=$( mktemp -p . )

echo "Creating run folder"
for manifest in $manifest_list
do
    (
    manifest_name=$( basename $manifest |  sed 's/\.[^.]*$//' )
    if [ -d $manifest_name ]
    then
        echo "$manifest_name folder found... checking content"
        if [ -e $manifest_name/$manifest_name.import.qza ]
        then
            echo "QZA file found, skipping run..."
            echo $manifest_name >> $tempcheck
            continue
        else
            echo "QZA not found, proceeding with import"
        fi
    else
        mkdir $manifest_name
    fi
    cp $manifest $manifest_name/

    echo "Importing $manifest_name Data into artifact file"
    $SINGULARITY_COMMAND qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path $manifest \
    --output-path $manifest_name/$manifest_name.import.qza \
    --input-format PairedEndFastqManifestPhred33 || exit_on_error

    echo "Summarizing $manifest_name importation into visualisation file"
    $SINGULARITY_COMMAND qiime demux summarize \
    --i-data $manifest_name/$manifest_name.import.qza \
    --p-n $p_n \
    --o-visualization $manifest_name/$manifest_name.import.qzv --verbose || exit_on_error
    
    echo $manifest_name >> $tempcheck
    ) &
    if [[ $(jobs -r -p | wc -l) -ge $NB_THREADS ]]; then
        wait -n
    fi
done
wait

if [ $( cat $tempcheck | wc -l ) -ne  $( echo $manifest_list | wc -w ) ]
then
    echo "Step finished with errors"
    exit 1
fi
rm $tempcheck

# LAST RESORT Check loop because of the multithreading#
#for manifest in $manifest_list
#do
#    manifest_name=$( basename $manifest |  sed 's/\.[^.]*$//' )
#    if [ ! -e $manifest_name/$manifest_name.import.qza ] || [ ! -e $manifest_name/$manifest_name.import.qzv ]
#    then
#        echo "Step finished with errors"
#        exit 1
#    fi
#done

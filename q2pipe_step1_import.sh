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

function ProgressBar {

	let _progress=(${1}*100/${2}*100)/100
	let _done=(${_progress}*4)/10
	let _left=40-$_done

	_done=$(printf "%${_done}s")
	_left=$(printf "%${_left}s")

printf "\rProgress : [${_done// /#}${_left// /-}] ${_progress}%%"

} # Reference : https://github.com/fearside/ProgressBar/ Author: Teddy Skarin

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
if [ "$manifest_list" == ""  ]
then
    echo "ERROR: no manifest file defined in $optionfile"
    exit 3
fi
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
            kill $BASHPID
        else
            echo "QZA not found, proceeding with import"
        fi
    else
        mkdir $manifest_name
    fi
    cp $manifest $manifest_name/

    echo "Importing $manifest_name Data into artifact file"
    $APPTAINER_COMMAND qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-path $manifest \
    --output-path $manifest_name/$manifest_name.import.qza \
    --input-format PairedEndFastqManifestPhred33 || exit_on_error

    echo "Summarizing $manifest_name importation into visualisation file"
    $APPTAINER_COMMAND qiime demux summarize \
    --i-data $manifest_name/$manifest_name.import.qza \
    --p-n $p_n \
    --o-visualization $manifest_name/$manifest_name.import.qzv --verbose || exit_on_error

    if [ "$RUN_FIGARO" == "true" ]
    then
        if [ -d $manifest_name/figaro_export ]
        then
            rm -Rf $manifest_name/figaro_export
        fi
        if [ -d $manifest_name/figaro_results ]
        then
            rm -Rf $manifest_name/figaro_results
        fi
        WORK_DIR=`mktemp --suffix=_figaro -d -p "$TMPDIR"`
        mkdir $WORK_DIR/$manifest_name
        echo  "Extracting data for Figaro execution"
        $APPTAINER_COMMAND qiime tools export \
        --input-path $manifest_name/$manifest_name.import.qza \
        --output-path $WORK_DIR/$manifest_name/figaro_export

        echo "Preparing sequences files..."
        sed 1d $WORK_DIR/$manifest_name/figaro_export/MANIFEST | while read line
        do
            samp_name=$( echo $line | awk -F',' '{ print $1 }' )
            file_name=$( echo $line | awk -F',' '{ print $2 }' )
            correct_name=$( echo $file_name | sed "s/"$samp_name"_[0-9]*_/"$samp_name"_/g" )
            #echo $samp_name
            #echo $file_name
            #echo $correct_name
            mv $WORK_DIR/$manifest_name/figaro_export/$file_name $WORK_DIR/$manifest_name/figaro_export/$correct_name
        done
        mkdir $WORK_DIR/$manifest_name/figaro_export/trimmed
        bigfile=$( ls -S $WORK_DIR/$manifest_name/figaro_export | head -n 1 | xargs -n 1 basename )

        $APPTAINER_COMMAND vsearch --fastq_stats $WORK_DIR/$manifest_name/figaro_export/$bigfile \
        --log $WORK_DIR/$manifest_name/figaro_export/trim_report.txt --quiet

        trimsize=$( grep ">=" $WORK_DIR/$manifest_name/figaro_export/trim_report.txt | awk -F' ' '{ print $2 }' )
        let $[ trimsize -= trim_offset ]
        echo "According to detected length, sequences will be trimmed to $trimsize"
        echo "Trimming sequences files..."
        totalfile=$( ls $WORK_DIR/$manifest_name/figaro_export/*.fastq.gz | wc -l )
        filedone=0
        for i in $( ls $WORK_DIR/$manifest_name/figaro_export/*.fastq.gz | xargs -n 1 basename )
        do
            $APPTAINER_COMMAND vsearch --fastq_filter $WORK_DIR/$manifest_name/figaro_export/$i \
            --fastq_trunclen $trimsize \
            --fastqout $WORK_DIR/$manifest_name/figaro_export/trimmed/$i --quiet
            let $[ filedone += 1]
            ProgressBar $filedone $totalfile
        done
        echo ""
        echo "Launching Figaro on $manifest_name/figaro_export/trimmed"
        mkdir $WORK_DIR/$manifest_name/figaro_results
        for amp in $( echo "$f_amplicon_size" | sed 's/,/ /g' )
        do
            echo "Amplicon size : $amp"
            $APPTAINER_COMMAND figaro -i $WORK_DIR/$manifest_name/figaro_export/trimmed -o $WORK_DIR/$manifest_name/figaro_results/AmpliconSize_$amp \
            --ampliconLength $amp \
            --forwardPrimerLength $f_forward_primer_len \
            --reversePrimerLength $f_reverse_primer_len \
            --minimumOverlap $f_min_overlap > $WORK_DIR/$manifest_name/figaro_results/AmpliconSize_$amp.txt
        done
        mv $WORK_DIR/$manifest_name/figaro_results $manifest_name/figaro_results
        if [ "$CLEAN_FIGARO_OUTPUT" == "true" ]
        then
            echo "Cleaning Figaro temporary files"
            rm -Rf $WORK_DIR
            #rm -Rf $manifest_name/figaro_export
        else
            mv $WORK_DIR/$manifest_name/figaro_export $manifest_name/figaro_results
            rm -Rf $WORK_DIR
        fi

    fi
    echo "$manifest_name DONE"
    echo $manifest_name >> $tempcheck
    ) &
    while [[ $(jobs -r -p | wc -l) -ge $NB_THREADS ]]; do
        # Replaced wait -n command because incompatible with Compute Canada Clusters (old bash version)
        sleep 1
    done
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

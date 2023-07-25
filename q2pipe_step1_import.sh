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

# Calculate number of threads available for each job
# Falco and Figaro will be able to leverage this
nb_manifest=$( echo $MANIFEST_FILE_PATH | sed 's/,/ /g' | wc -w )
threads_per_job=$( expr $NB_THREADS / $nb_manifest )
if [ $threads_per_job -eq 0 ]
then
    # 0 means there is less thread than manifest, so only 1 thread will be used by subprocesses
    threads_per_job=1
fi

echo "DEBUG: Number of threads available for each mainfest: $threads_per_job"

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
    if [ "$RUN_FIGARO" == "true" ] || [ "$RUN_FALCO" == "true" ]
    then
        SEQS_DIR=`mktemp --suffix=_export -d -p "$TMPDIR"`
        mkdir $SEQS_DIR/$manifest_name
        echo  "Extracting data for secondary processes execution"
        $APPTAINER_COMMAND qiime tools export \
        --input-path $manifest_name/$manifest_name.import.qza \
        --output-path $SEQS_DIR/$manifest_name/sequences_export
    fi
     
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
#        echo  "Extracting data for Figaro execution"
#        $APPTAINER_COMMAND qiime tools export \
#        --input-path $manifest_name/$manifest_name.import.qza \
#        --output-path $WORK_DIR/$manifest_name/figaro_export
        mkdir $WORK_DIR/$manifest_name/figaro_export
        echo "Preparing sequences files..."
        sed 1d $SEQS_DIR/$manifest_name/sequences_export/MANIFEST | while read line
        do
            samp_name=$( echo $line | awk -F',' '{ print $1 }' )
            file_name=$( echo $line | awk -F',' '{ print $2 }' )
            correct_name=$( echo $file_name | sed "s/"$samp_name"_[0-9]*_/"$samp_name"_/g" )
            #echo $samp_name
            #echo $file_name
            #echo $correct_name
            ln -s $SEQS_DIR/$manifest_name/sequences_export/$file_name $WORK_DIR/$manifest_name/figaro_export/$correct_name
        done
        mkdir $WORK_DIR/$manifest_name/figaro_export/trimmed
        bigfile=$( ls -S -L $WORK_DIR/$manifest_name/figaro_export | head -n 1 | xargs -n 1 basename )

        $APPTAINER_COMMAND vsearch --fastq_stats $WORK_DIR/$manifest_name/figaro_export/$bigfile \
        --log $WORK_DIR/$manifest_name/figaro_export/trim_report.txt --quiet

        trimsize=$( grep ">=" $WORK_DIR/$manifest_name/figaro_export/trim_report.txt | awk -F' ' '{ print $2 }' )
        let $[ trimsize -= figaro_trim_offset ]
        echo "According to detected length, sequences will be trimmed to $trimsize"
        echo "Trimming sequences files..."
        totalfile=$( ls $WORK_DIR/$manifest_name/figaro_export/*.f*q.gz | wc -l )
        filedone=0
        vsearch_running_job=0
        ProgressBar $filedone $totalfile
        for i in $( ls $WORK_DIR/$manifest_name/figaro_export/*.f*q.gz | xargs -n 1 basename )
        do
            $APPTAINER_COMMAND vsearch --fastq_filter $WORK_DIR/$manifest_name/figaro_export/$i \
            --fastq_trunclen $trimsize \
            --fastqout $WORK_DIR/$manifest_name/figaro_export/trimmed/$i --quiet &
            let $[ vsearch_running_job += 1 ]
            if [ $vsearch_running_job -eq $threads_per_job ] # Not very efficient, but must not conflict with manifest parallelism
            then
                wait
                vsearch_running_job=0
                let $[ filedone += threads_per_job]
                ProgressBar $filedone $totalfile
            fi
        done
        wait
        ProgressBar $totalfile $totalfile
        echo ""
        echo "Launching Figaro on $manifest_name/figaro_export/trimmed"
        mkdir $WORK_DIR/$manifest_name/figaro_results
        
        for amp in $( echo "$f_amplicon_size" | sed 's/,/ /g' )
        do
            echo "Amplicon size : $amp"
            # Require figaro version from Patg13 repo (cores argument)
            $APPTAINER_COMMAND figaro -i $WORK_DIR/$manifest_name/figaro_export/trimmed -o $WORK_DIR/$manifest_name/figaro_results/AmpliconSize_$amp \
            --ampliconLength $amp \
            --forwardPrimerLength $f_forward_primer_len \
            --reversePrimerLength $f_reverse_primer_len \
            --minimumOverlap $f_min_overlap \
            --cores $threads_per_job > $WORK_DIR/$manifest_name/figaro_results/AmpliconSize_$amp.txt
            #let $[ figaro_running_job += 1 ]
            #if [ $figaro_running_job -eq $threads_per_job ] # Not very efficient, but must not conflict with manifest parallelism
            #then
            #    echo "DEBUG WAITING BEFORE"
            #    wait
            #    echo "DEBUG WAITING AFTER"
            #    figaro_running_job=0
            #fi
        done
        wait
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
        echo "Figaro analysis finished"
        echo ""
    fi
    if [ "$RUN_FALCO" == "true" ]
    then
        if [ -d $manifest_name/falco_export ]
        then
            rm -Rf $manifest_name/falco_export
        fi
        if [ -d $manifest_name/falco_results ]
        then
            rm -Rf $manifest_name/falco_results
        fi
        WORK_DIR=`mktemp --suffix=_falco -d -p "$TMPDIR"`
        mkdir $WORK_DIR/$manifest_name
        mkdir $WORK_DIR/$manifest_name/falco_export
        head -n 1 $SEQS_DIR/$manifest_name/sequences_export/MANIFEST > $SEQS_DIR/$manifest_name/sequences_export/MANIFEST_COR
        sed 1d $SEQS_DIR/$manifest_name/sequences_export/MANIFEST | while read line
        do
            samp_name=$( echo $line | awk -F',' '{ print $1 }' )
            file_name=$( echo $line | awk -F',' '{ print $2 }' )
            direction=$( echo $line | awk -F',' '{ print $3 }' )
            correct_name=$( echo $file_name | sed "s/"$samp_name"_[0-9]*_/"$samp_name"_/g" )
            #echo $samp_name
            #echo $file_name
            #echo $correct_name
            echo "$samp_name,$correct_name,$direction" >> $SEQS_DIR/$manifest_name/sequences_export/MANIFEST_COR
            ln -s $SEQS_DIR/$manifest_name/sequences_export/$file_name $WORK_DIR/$manifest_name/falco_export/$correct_name
        done
        falco_filelist=$( ls $WORK_DIR/$manifest_name/falco_export/*.f*q.gz )
        if [ "$FALCO_COMBINED_RUN" == "true" ]
        then
            echo "Creating a combined run files (all R1 and all R2) for $manifest_name"
            # Gain a little more time by running in parallel if thread per job allows it
            if [ $threads_per_job -gt 1 ]
            then
                cat $( basename -a $( awk -F',' '{if ($3=="forward") print $2  }' $SEQS_DIR/$manifest_name/sequences_export/MANIFEST_COR ) | awk -v pre=$WORK_DIR/$manifest_name/falco_export/ '{ print pre$1 }' ) > $WORK_DIR/$manifest_name/falco_export/$manifest_name.R1.fastq.gz &
                cat $( basename -a $( awk -F',' '{if ($3=="reverse") print $2  }' $SEQS_DIR/$manifest_name/sequences_export/MANIFEST_COR ) | awk -v pre=$WORK_DIR/$manifest_name/falco_export/ '{ print pre$1 }' ) > $WORK_DIR/$manifest_name/falco_export/$manifest_name.R2.fastq.gz &
                wait
            else
                # Run in serial if not
                cat $( basename -a $( awk -F',' '{if ($3=="forward") print $2  }' $SEQS_DIR/$manifest_name/sequences_export/MANIFEST_COR ) | awk -v pre=$WORK_DIR/$manifest_name/falco_export/ '{ print pre$1 }' ) > $WORK_DIR/$manifest_name/falco_export/$manifest_name.R1.fastq.gz
                cat $( basename -a $( awk -F',' '{if ($3=="reverse") print $2  }' $SEQS_DIR/$manifest_name/sequences_export/MANIFEST_COR ) | awk -v pre=$WORK_DIR/$manifest_name/falco_export/ '{ print pre$1 }' ) > $WORK_DIR/$manifest_name/falco_export/$manifest_name.R2.fastq.gz
            fi
            # To prevent the two combined files to be added in the same chunk in falco
            falco_filelist="$WORK_DIR/$manifest_name/falco_export/$manifest_name.R1.fastq.gz "$falco_filelist" $WORK_DIR/$manifest_name/falco_export/$manifest_name.R2.fastq.gz"
        fi
        mkdir $WORK_DIR/$manifest_name/falco_results
        echo ""
        echo "Running Falco on $manifest_name/falco_export"
        $APPTAINER_COMMAND falco -t $threads_per_job -m $falco_right_trim --nogroup -q $falco_filelist
        mv $WORK_DIR/$manifest_name/falco_export/*.html $WORK_DIR/$manifest_name/falco_results
        mv $WORK_DIR/$manifest_name/falco_export/*.txt  $WORK_DIR/$manifest_name/falco_results
        echo ""
        mv $WORK_DIR/$manifest_name/falco_results $manifest_name/falco_results
        if [ "$CLEAN_FALCO_OUTPUT" == "true" ]
        then
            echo "Cleaning Falco temporary files"
            rm -Rf $WORK_DIR
            #rm -Rf $manifest_name/figaro_export
        else
            mv $WORK_DIR/$manifest_name/falco_export $manifest_name/falco_results
            rm -Rf $WORK_DIR
        fi
        echo "Falco analysis finished"
        echo ""
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

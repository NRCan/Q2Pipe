#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#     Step 2 - Denoising       #
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

echo "Checking run folders"
for manifest in $manifest_list
do
    manifest_name=$( basename $manifest |  sed 's/\.[^.]*$//' )
    if [ -d $manifest_name ]
    then
        echo "Checking $manifest_name folder content"
        if [ -e $manifest_name/$manifest_name.table-dada2.qza ]
        then
            echo "QZA file found, skipping run..."
            continue
        else
            echo "QZA not found, proceeding with denoising"
        fi
    else
        echo "ERROR: $manifest_name folder not found"
        exit 1
    fi

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
        --i-demultiplexed-sequences $manifest_name/$manifest_name.import.qza  \
        --o-trimmed-sequences $manifest_name/$manifest_name.import$ca_flag.qza  \
        --p-match-adapter-wildcards \
        $forward_trim_param $forward_primer \
        $reverse_trim_param $reverse_primer \
        $untrimmed_flag --p-cores $NB_THREADS --verbose || exit_on_error

        echo "Summarizing Cutadapt trimming into visualisation file"
        $SINGULARITY_COMMAND qiime demux summarize \
        --i-data $manifest_name/$manifest_name.import$ca_flag.qza \
        --o-visualization $manifest_name/$manifest_name.import$ca_flag.qzv --verbose
    fi



    $SINGULARITY_COMMAND qiime dada2 denoise-paired \
    --i-demultiplexed-seqs $manifest_name/$manifest_name.import$ca_flag.qza \
    --o-table $manifest_name/$manifest_name.table-dada2.qza \
    --o-representative-sequences $manifest_name/$manifest_name.rep-seqs-dada2.qza \
    --o-denoising-stats $manifest_name/$manifest_name.denoising-stats-dada2.qza \
    --p-trim-left-f $p_trim_left_f \
    --p-trim-left-r $p_trim_left_r \
    --p-trunc-len-f $p_trunc_len_f \
    --p-trunc-len-r $p_trunc_len_r \
    --p-max-ee-f $p_max_ee_f \
    --p-max-ee-r $p_max_ee_r \
    --p-n-threads $NB_THREADS \
    --p-n-reads-learn $p_n_reads_learn \
    --p-chimera-method $p_chimera_method \
    --p-min-fold-parent-over-abundance $p_min_fold_parent_over_abundance --verbose || exit_on_error

    $SINGULARITY_COMMAND qiime feature-table summarize \
    --i-table $manifest_name/$manifest_name.table-dada2.qza \
    --o-visualization $manifest_name/$manifest_name.table-dada2.qzv --verbose

    $SINGULARITY_COMMAND qiime metadata tabulate \
    --m-input-file $manifest_name/$manifest_name.denoising-stats-dada2.qza \
    --o-visualization $manifest_name/$manifest_name.denoising-stats-dada2.qzv

    $SINGULARITY_COMMAND qiime feature-table tabulate-seqs \
    --i-data $manifest_name/$manifest_name.rep-seqs-dada2.qza \
    --o-visualization $manifest_name/$manifest_name.rep-seqs-dada2.qzv
    
    # If only working with a single manifest, print important data for step 3
    if [ $( echo $manifest_list | wc -w ) -eq 1 ]
    then
        echo "Extracting Mean sample frequency"
        $SINGULARITY_COMMAND qiime tools export --input-path $manifest_name/$manifest_name.table-dada2.qzv --output-path $manifest_name/$manifest_name.temporary_export_dada2table


        mean_line=$( grep -n "Mean frequency" $manifest_name/$manifest_name.temporary_export_dada2table/index.html | head -n 1 | cut -f1 -d: )
        let $[ mean_line += 1 ]

        freq=$( head -n $mean_line $manifest_name/$manifest_name.temporary_export_dada2table/index.html | tail -n 1 | sed 's/ //g' | sed 's/<td>//g' | sed 's;</td>;;g' )

        echo ""
        echo "Mean frequency: $freq"
        freq=$( echo $freq | sed 's/,//g' )
        freq_n=$( $SINGULARITY_COMMAND python -c "exec(\"import math\nprint($freq*0.0005)\")" )
        freq_f=$( $SINGULARITY_COMMAND python -c "exec(\"import math\nprint(math.floor($freq*0.0005))\")" )
        freq_c=$( $SINGULARITY_COMMAND python -c "exec(\"import math\nprint(math.ceil($freq*0.0005))\")" )
        echo "Recommended filtration setting (0.05%): $freq_n = $freq_f (floor) or $freq_c (ceiling)"
        rm -rf $manifest_name/$manifest_name.temporary_export_dada2table
    fi

done

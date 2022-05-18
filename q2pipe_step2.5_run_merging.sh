#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#    Step 2.5 - Run Merging    #
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

if [ $( echo $manifest_list | wc -w ) -eq 1 ]
then
    echo "Only one manifest defined in your option file, you must skip this step"
    exit 0
fi

merge_table_list=""
merge_repseqs_list=""


echo "Checking run folders"
for manifest in $manifest_list
do
   manifest_name=$( basename $manifest |  sed 's/\.[^.]*$//' )
   if [ ! -e $manifest_name/$manifest_name.table-dada2.qza ] || [ ! -e $manifest_name/$manifest_name.rep-seqs-dada2.qza ]
   then
        echo "ERROR: $manifest_name folder miss table-dada2 or rep-seqs-dada2, merging cannot proceed"
        exit 1
   fi
   merge_table_list="$merge_table_list $manifest_name/$manifest_name.table-dada2.qza"
   merge_repseqs_list="$merge_repseqs_list $manifest_name/$manifest_name.rep-seqs-dada2.qza"
   ext_folder=$( $SINGULARITY_COMMAND qiime tools extract --input-path $manifest_name/$manifest_name.table-dada2.qza --output-path $ANALYSIS_NAME.mergecheck | sed 's:.*/::' )
   
   check_file=$ANALYSIS_NAME.mergecheck/$ext_folder/provenance/action/action.yaml 
   end_line=$( grep -n "min_overlap:" $check_file | awk -F: '{ print $1 }' )
   head -n $end_line $check_file | tail -n 8 > $ANALYSIS_NAME.mergecheck/$manifest_name.check
   grep "chimera_method:" $check_file >> $ANALYSIS_NAME.mergecheck/$manifest_name.check
done

compare=$( sha256sum MULTIRUN_BASIC_TEST.mergecheck/*.check | awk '{ print $1 }' | sort | uniq | wc -l )

if [ $compare -ne 1 ]
then
    sha256sum MULTIRUN_BASIC_TEST.mergecheck/*.check
    for i in $( ls MULTIRUN_BASIC_TEST.mergecheck/*.check )
    do
      echo $i
      cat $i
      echo ""
    done
    if [ "$IGNORE_INCOMPATIBILITY" == "false" ]
    then
        echo "ERROR: Incompatible run detected and incompatibility enforcement is active"
        echo "Every run must have the same denoising and chimera removal parameters"
        exit 1
    else
        echo "WARNING: Incompatible run detected but incompatibility enforcement is inactive"
        echo "You REALLY should make sure every run have the same denoising and chimera removal parameters"
    fi
fi

echo "Merging runs"

#echo $merge_table_list
#echo $merge_repseqs_list

$SINGULARITY_COMMAND qiime feature-table merge \
--i-tables $merge_table_list \
--o-merged-table $ANALYSIS_NAME.table-dada2.qza || exit_on_error

$SINGULARITY_COMMAND qiime feature-table merge-seqs \
--i-data $merge_repseqs_list \
--o-merged-data $ANALYSIS_NAME.rep-seqs-dada2.qza  || exit_on_error

$SINGULARITY_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2.qza \
--o-visualization $ANALYSIS_NAME.table-dada2.qzv --verbose

$SINGULARITY_COMMAND qiime feature-table tabulate-seqs \
--i-data $ANALYSIS_NAME.rep-seqs-dada2.qza \
--o-visualization $ANALYSIS_NAME.rep-seqs-dada2.qzv


echo "Extracting Mean sample frequency"
$SINGULARITY_COMMAND qiime tools export --input-path $ANALYSIS_NAME.table-dada2.qzv --output-path $ANALYSIS_NAME.temporary_export_dada2table


mean_line=$( grep -n "Mean frequency" $ANALYSIS_NAME.temporary_export_dada2table/index.html | head -n 1 | cut -f1 -d: )
let $[ mean_line += 1 ]

freq=$( head -n $mean_line $ANALYSIS_NAME.temporary_export_dada2table/index.html | tail -n 1 | sed 's/ //g' | sed 's/<td>//g' | sed 's;</td>;;g' )

echo ""
echo "Mean frequency: $freq"
freq=$( echo $freq | sed 's/,//g' )
freq_n=$( $SINGULARITY_COMMAND python -c "exec(\"import math\nprint($freq*0.0005)\")" )
freq_f=$( $SINGULARITY_COMMAND python -c "exec(\"import math\nprint(math.floor($freq*0.0005))\")" )
freq_c=$( $SINGULARITY_COMMAND python -c "exec(\"import math\nprint(math.ceil($freq*0.0005))\")" )
echo "Recommended filtration setting (0.05%): $freq_n = $freq_f (floor) or $freq_c (ceiling)"
rm -rf $ANALYSIS_NAME.temporary_export_dada2table


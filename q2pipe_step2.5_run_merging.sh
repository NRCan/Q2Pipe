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

if [ -d $ANALYSIS_NAME.mergecheck ]
then
    echo "ERROR: $ANALYSIS_NAME.mergecheck folder already exist"
    echo "Please delete this folder and relaunch the step"
    exit 2
fi

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
   ext_folder=$( $APPTAINER_COMMAND qiime tools extract --input-path $manifest_name/$manifest_name.table-dada2.qza --output-path $ANALYSIS_NAME.mergecheck | sed 's:.*/::' )
   
   check_file=$ANALYSIS_NAME.mergecheck/$ext_folder/provenance/action/action.yaml 
   end_line=$( grep -n "min_overlap:" $check_file | awk -F: '{ print $1 }' )
   head -n $end_line $check_file | tail -n 6 > $ANALYSIS_NAME.mergecheck/$manifest_name.check
   grep "chimera_method:" $check_file >> $ANALYSIS_NAME.mergecheck/$manifest_name.check
done

compare=$( sha256sum $ANALYSIS_NAME.mergecheck/*.check | awk '{ print $1 }' | sort | uniq | wc -l )

if [ $compare -ne 1 ]
then
    sha256sum $ANALYSIS_NAME.mergecheck/*.check
    for i in $( ls $ANALYSIS_NAME.mergecheck/*.check )
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

$APPTAINER_COMMAND qiime feature-table merge \
--i-tables $merge_table_list \
--o-merged-table $ANALYSIS_NAME.table-dada2.qza || exit_on_error

$APPTAINER_COMMAND qiime feature-table merge-seqs \
--i-data $merge_repseqs_list \
--o-merged-data $ANALYSIS_NAME.rep-seqs-dada2.qza  || exit_on_error

$APPTAINER_COMMAND qiime feature-table summarize \
--i-table $ANALYSIS_NAME.table-dada2.qza \
--o-visualization $ANALYSIS_NAME.table-dada2.qzv --verbose

$APPTAINER_COMMAND qiime feature-table tabulate-seqs \
--i-data $ANALYSIS_NAME.rep-seqs-dada2.qza \
--o-visualization $ANALYSIS_NAME.rep-seqs-dada2.qzv

# Include PCoA for 

$APPTAINER_COMMAND qiime diversity beta \
--i-table $ANALYSIS_NAME.table-dada2.qza \
--p-metric jaccard \
--p-n-jobs $NB_THREADS \
--o-distance-matrix $ANALYSIS_NAME.mergecheck/merge_distancematrix.qza

$APPTAINER_COMMAND qiime diversity pcoa \
--i-distance-matrix $ANALYSIS_NAME.mergecheck/merge_distancematrix.qza \
--o-pcoa $ANALYSIS_NAME.mergecheck/merge_pcoa.qza

$APPTAINER_COMMAND qiime emperor plot \
--i-pcoa $ANALYSIS_NAME.mergecheck/merge_pcoa.qza \
--m-metadata-file $METADATA_FILE_PATH \
--o-visualization $ANALYSIS_NAME.mergeplot.qzv

echo "Extracting Mean sample frequency"
$APPTAINER_COMMAND qiime tools export --input-path $ANALYSIS_NAME.table-dada2.qzv --output-path $ANALYSIS_NAME.temporary_export_dada2table


mean_line=$( grep -n "Mean frequency" $ANALYSIS_NAME.temporary_export_dada2table/index.html | head -n 1 | cut -f1 -d: )

freq=$( head -n $mean_line $ANALYSIS_NAME.temporary_export_dada2table/index.html | tail -n 1 | awk -F',' '{ print $6}' | sed 's/\"Mean frequency\"://g' | sed 's/}//g' | sed 's/{//g' )

echo ""
echo "Mean frequency: $freq"
freq=$( echo $freq | sed 's/,//g' )
freq_n=$( $APPTAINER_COMMAND python -c "exec(\"import math\nprint($freq*0.0005)\")" )
freq_f=$( $APPTAINER_COMMAND python -c "exec(\"import math\nprint(math.floor($freq*0.0005))\")" )
freq_c=$( $APPTAINER_COMMAND python -c "exec(\"import math\nprint(math.ceil($freq*0.0005))\")" )
echo "Recommended filtration setting (0.05%): $freq_n = $freq_f (floor) or $freq_c (ceiling)"
echo "You can also use p_min_frequency=2 to only remove singletons"
rm -rf $ANALYSIS_NAME.temporary_export_dada2table


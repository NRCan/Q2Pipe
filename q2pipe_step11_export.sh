#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#    Step 11 - Exportation     #
#      December 16, 2022       #
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

if [ ! $TMPDIR ]
then
    export TMPDIR=/tmp
fi

if [ "$APPTAINER_COMMAND" != "" ]
then
    echo "DEBUG: Checking temporary folder"
    temp_check=$( $APPTAINER_COMMAND mktemp -t Q2PIPE_TEMPFOLDER_CHECK.XXXXXX.temp  )
    bname=$( basename $temp_check )
    if [ ! -e $TMPDIR/$bname ]
    then
        echo "ERROR: Disparity between Apptainer temporary folder and system temporary folder"
        echo "Please make sure both are pointing to the same folder"
        exit 5
    else
        echo "DEBUG: Temporary file check status: OK"
        rm $TMPDIR/Q2PIPE_TEMPFOLDER_CHECK.??????.temp
    fi
fi

if  [ "$GENERATE_ANCOM" == "true" ] && [ ! $m_metadata_column ]
then
    echo "ERROR: m_metadata_column not set in the option file"
    echo "This parameter is mandatory for ANCOM analysis"
    exit 3
fi


if [ "$SKIP_RAREFACTION" == "true" ] || [ "$SKIP_RAREFACTION" == "both" ]
then
    $APPTAINER_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity"

    $APPTAINER_COMMAND biom convert \
    -i $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity"/feature-table.biom \
    -o $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity"/$ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".tsv --to-tsv

    $APPTAINER_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"

    sed -i 's/Feature ID/#OTUID/g' $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"/taxonomy.tsv
    sed -i 's/Taxon/taxonomy/g' $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"/taxonomy.tsv
    sed -i 's/Confidence/confidence/g' $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"/taxonomy.tsv

    $APPTAINER_COMMAND biom add-metadata \
    -i $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity"/feature-table.biom \
    --observation-metadata-fp $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"/taxonomy.tsv \
    --sc-separated taxonomy \
    -o $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"/feature_taxonomy_merged.biom

    $APPTAINER_COMMAND biom convert \
    -i $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"/feature_taxonomy_merged.biom \
    -o $ANALYSIS_NAME.ASV_table_norarefaction_dn"$p_perc_identity".tsv --to-tsv --header-key taxonomy

    sed -i '1d' $ANALYSIS_NAME.ASV_table_norarefaction_dn"$p_perc_identity".tsv

    $APPTAINER_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"

    if [ "$( $APPTAINER_COMMAND which ASV_Table_DNA_Merger.py )" != "" ]
    then
        $APPTAINER_COMMAND ASV_Table_DNA_Merger.py \
        --fasta $ANALYSIS_NAME.asv_tax_dir_dn"$p_perc_identity"/dna-sequences.fasta \
        --asv-table $ANALYSIS_NAME.ASV_table_norarefaction_dn"$p_perc_identity".tsv \
        --out $ANALYSIS_NAME.ASV_tableSeqs_norarefaction_dn"$p_perc_identity".tsv || echo "WARNING: ASV_Table_DNA_Merger not installed"
    else
       echo "WARNING: ASV_Table_DNA_Merger.py not available in PATH"
       echo "ASV table merge with DNA sequences cannot be done"
    fi

    if [ "$GENERATE_FUNGUILD" == "true" ]
    then
        echo "Running FUNGuild analysis..."
        $APPTAINER_COMMAND Guilds_v1.1.py \
        -otu $ANALYSIS_NAME.ASV_table_norarefaction_dn"$p_perc_identity".tsv \
        -m -u -db $FUNGUILD_DATABASE_PATH
    fi
fi

if [ "$SKIP_RAREFACTION" == "false" ] || [ "$SKIP_RAREFACTION" == "both" ]
then
    $APPTAINER_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"

    $APPTAINER_COMMAND biom convert \
    -i $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"/feature-table.biom \
    -o $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"/$ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity".tsv --to-tsv

    $APPTAINER_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"
   
    sed -i 's/Feature ID/#OTUID/g' $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/taxonomy.tsv
    sed -i 's/Taxon/taxonomy/g' $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/taxonomy.tsv
    sed -i 's/Confidence/confidence/g' $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/taxonomy.tsv
   
    $APPTAINER_COMMAND biom add-metadata \
    -i $ANALYSIS_NAME.rarefied_"$p_sampling_depth"_filtered_table_dn"$p_perc_identity"/feature-table.biom \
    --observation-metadata-fp $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/taxonomy.tsv \
    --sc-separated taxonomy \
    -o $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/feature_taxonomy_merged.biom

    $APPTAINER_COMMAND biom convert \
    -i $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/feature_taxonomy_merged.biom \
    -o $ANALYSIS_NAME.ASV_table_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".tsv --to-tsv --header-key taxonomy

    sed -i '1d' $ANALYSIS_NAME.ASV_table_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".tsv

    $APPTAINER_COMMAND qiime tools export \
    --input-path $ANALYSIS_NAME.filtered_rep-seqs-dada2_dn"$p_perc_identity".qza \
    --output-path $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"

    if [ "$( $APPTAINER_COMMAND which ASV_Table_DNA_Merger.py )" != "" ]
    then
        $APPTAINER_COMMAND ASV_Table_DNA_Merger.py \
        --fasta $ANALYSIS_NAME.asv_tax_dir_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"/dna-sequences.fasta \
        --asv-table $ANALYSIS_NAME.ASV_table_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".tsv \
        --out $ANALYSIS_NAME.ASV_tableSeqs_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".tsv || echo "WARNING: ASV_Table_DNA_Merger not installed"
    else
       echo "WARNING: ASV_Table_DNA_Merger.py not available in PATH"
       echo "ASV table merge with DNA sequences cannot be done"
    fi

    if [ "$GENERATE_FUNGUILD" == "true" ]
    then
        echo "Running FUNGuild analysis..."
        $APPTAINER_COMMAND Guilds_v1.1.py \
        -otu $ANALYSIS_NAME.ASV_table_rarefied_"$p_sampling_depth"_dn"$p_perc_identity".tsv \
        -m -u -db $FUNGUILD_DATABASE_PATH
    fi
fi

if [ $EXTRACTION_FORM_PATH ]
then
    if [ ! -e $EXTRACTION_FORM_PATH ]
    then
        echo "ERROR: Extraction form $EXTRACTION_FORM_PATH not found"
        exit 1
    fi

    echo "Extracting results files according to $EXTRACTION_FORM_PATH"
    mkdir "$ANALYSIS_NAME"_form_extraction 2>/dev/null
    head -n 1 $EXTRACTION_FORM_PATH > "$ANALYSIS_NAME"_form_extraction/extraction_form.tsv
    
    # NOTICE: use sed 's/,/ /g'  to remove , from the file before converting to CSV (better to not use , in form)
    cat $EXTRACTION_FORM_PATH | sed 's/\t/,/g' | while read line
    do
        if [ "$( echo $line | awk -F',' '{ print $2 }' )" != "True" ]
        then
            continue
        fi
        #echo $line
        if [ "$( echo $line | grep MANIFEST_NAME )" != "" ]
        then
            filetype=$( echo $line | awk -F',' '{ print $6 }' | sed 's;./MANIFEST_NAME/MANIFEST_NAME.;;g' )
            filenames=$( find -maxdepth 2 -mindepth 2  -wholename "./*/*.$filetype" -type f )
            cp -R --parent $filenames "$ANALYSIS_NAME"_form_extraction/
            echo $line | sed 's/,/\t/g' >> "$ANALYSIS_NAME"_form_extraction/extraction_form.tsv
            continue
        fi
        not_found_tag=0
        filename=$( echo $line | awk -F',' '{ print $6 }' | sed "s/ANALYSIS_NAME/$ANALYSIS_NAME/g" | sed "s/RARELEVEL/$p_sampling_depth/g" | sed "s/FREQLEVEL/$p_min_frequency/g" | sed "s/SAMPLEVEL/$p_min_samples/g" | sed "s/CLUSTID/$p_perc_identity/g" )
        # Looping trough files is better for multiple folder cases (beta_metrics)
        for files in $filename
        do
            #echo $files
            if [ ! -e $files ]
            then
                not_found_tag=1
            fi
        done
        if [ $not_found_tag -eq 1 ]
        then
            echo "WARNING: $filename not found"
            continue
        fi
        #echo $filename
        #if [ ! -e $filename ]
        #then
        #    echo "WARNING: $filename not found"
        #    continue
        #fi
        cp -R --parent $filename "$ANALYSIS_NAME"_form_extraction/
        echo $line | sed 's/,/\t/g' >> "$ANALYSIS_NAME"_form_extraction/extraction_form.tsv
    done
fi


if [ "$GENERATE_ANCOM" == "true" ]
then
    echo "Preparing ANCOM analysis"
    if [ ! -d "$ANALYSIS_NAME"_ANCOM ]
    then
        mkdir "$ANALYSIS_NAME"_ANCOM 
    fi

    $APPTAINER_COMMAND qiime taxa collapse \
    --i-table $ANALYSIS_NAME.filtered_table_dn"$p_perc_identity".qza \
    --i-taxonomy $ANALYSIS_NAME.taxo_dn"$p_perc_identity".qza \
    --p-level $p_level \
    --o-collapsed-table "$ANALYSIS_NAME"_ANCOM/feature_table_ANCOM.qza || exit_on_error

    $APPTAINER_COMMAND qiime composition add-pseudocount \
    --i-table "$ANALYSIS_NAME"_ANCOM/feature_table_ANCOM.qza \
    --o-composition-table "$ANALYSIS_NAME"_ANCOM/composition_table_ANCOM.qza || exit_on_error

    m_metadata_column=$( echo $m_metadata_column | sed 's/,/ /g' )
    
    for col in $m_metadata_column
    do
        echo "Generating ANCOM for column $col"
        $APPTAINER_COMMAND qiime composition ancom  \
        --i-table "$ANALYSIS_NAME"_ANCOM/composition_table_ANCOM.qza \
        --m-metadata-file $METADATA_FILE_PATH \
        --m-metadata-column $col \
        --o-visualization "$ANALYSIS_NAME"_ANCOM/ANCOM_"$col"_results.qzv || exit_on_error
    done

fi

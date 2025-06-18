#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#   By: Patrick Gagne (NRCan)  #
#   Tool - SRS normalization   #
#          Shiny App           #
#        June 18, 2025         #
#                              #
################################

# WARNING : UNTESTED SCRIPT
# This script is designed to run the SRS normalization Shiny app on a qiime2 artifact file.
# It requires the custom SRS package to be installed in the R environment used by the app.
# https://github.com/Patg13/SRS

exit_on_error(){
   echo "Qiime2 command error detected"
   echo "Exiting program"
   exit 1
}

exit_on_ctrl_c(){
   echo ""
   echo "Ctrl+C detected. Cleaning up temporary files..."
   if [ -d "$TSV_DIR" ]; then
      rm -rf "$TSV_DIR"
      echo "Temporary directory removed: $TSV_DIR"
   fi
   echo "Exiting program"
   exit 130  # Standard exit code for Ctrl+C
}

# Set up trap to catch Ctrl+C
trap exit_on_ctrl_c INT

qzafile=$1

if [ ! $qzafile ] || [ ! -e $qzafile ] || [ ! -r $qzafile ]
then
    echo "ERROR: you must specify a valid, accessible qiime2 artifact file"
    exit 1
fi

if [ "$qzafile" == "-h" ] || [ "$qzafile" == "--help" ]
then
    echo "Usage: $0 <qiime2_artifact_file.qza>"
    echo "This script is used to run the SRS normalization help app on qiime2 artifacts."
    exit 0
fi

if [ ! $TMPDIR ]
then
    export TMPDIR=/tmp
fi
TSV_DIR=`mktemp --suffix=_export -d -p "$TMPDIR"`

TSV_NAME=$( basename $qzafile )

$APPTAINER_COMMAND Convert_Biom_to_TSV.py -q $qzafile -t $TSV_DIR/$TSV_NAME.tsv
$APPTAINER_COMMAND Rscript -e "library(SRS) ; SRS.shiny.app.tsv(\"$TSV_DIR/$TSV_NAME.tsv\")"



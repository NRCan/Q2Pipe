#!/bin/bash

################################
#                              #
#      Qiime 2 Pipeline        #
#  By: Patrick Gagne (NRCan)   #
#      "Full Auto" mode        #
#       October 21, 2021        #
#                              #
################################

# This script is designed to launch a full analysis without any user interaction

exit_on_error(){
   echo "Step error detected"
   echo "Exiting program"
   exit 1
}


optionfile=$1
override_value=$2

if [ ! $override_value ]
then
    override_value=0
fi

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


if [ ! $Q2P ]
then
    echo "WARNING: Q2P environment variable not set"
    echo "The fullauto mode requires this variable to work"
    echo "Setting temporary Q2P variable"
    SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    export Q2P=$SCRIPT_DIR
fi

echo "Installation path: $Q2P"

invalid_next=0
if [ $override_value -gt 0 ]
then
    invalid_next=1
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step1.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 1 ]
then
    echo "Launching Step 1"
    if [ -e $ANALYSIS_NAME.q2pipe_step1.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step1.DONE
    fi
    $Q2P/q2pipe_step1_import.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step1.DONE
    invalid_next=1
else
    echo "Step 1 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step2.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 2 ]
then
    echo "Launching Step 2"
    if [ -e $ANALYSIS_NAME.q2pipe_step2.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step2.DONE
    fi
    $Q2P/q2pipe_step2_denoise.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step2.DONE
    invalid_next=1
else
    echo "Step 2 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step2.5.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 2 ]
then
    echo "Launching Step 2.5"
    if [ -e $ANALYSIS_NAME.q2pipe_step2..5.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step2.5.DONE
    fi

    if [ -d $ANALYSIS_NAME.mergecheck ]
    then
        rm $ANALYSIS_NAME.mergecheck -rf
    fi

    $Q2P/q2pipe_step2.5_run_merging.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step2.5.DONE
    invalid_next=1
else
    echo "Step 2.5 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step3.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 3 ]
then
    echo "Launching Step 3"
    if [ -e $ANALYSIS_NAME.q2pipe_step3.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step3.DONE
    fi
    $Q2P/q2pipe_step3_feature_filtering.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step3.DONE
    invalid_next=1
else
    echo "Step 3 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step4.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 4 ]
then
    echo "Launching Step 4"
    if [ -e $ANALYSIS_NAME.q2pipe_step4.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step4.DONE
    fi
    $Q2P/q2pipe_step4_denovo_clustering.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step4.DONE
    invalid_next=1
else
    echo "Step 4 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step5.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 5 ]
then
    echo "Launching Step 5"
    if [ -e $ANALYSIS_NAME.q2pipe_step5.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step5.DONE
    fi
    $Q2P/q2pipe_step5_classification.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step5.DONE
    invalid_next=1
else
    echo "Step 5 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step6.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 6 ]
then
    echo "Launching Step 6"
    if [ -e $ANALYSIS_NAME.q2pipe_step6.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step6.DONE
    fi
    $Q2P/q2pipe_step6_taxa_filtering.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step6.DONE
    invalid_next=1
else
    echo "Step 6 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step7.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 7 ]
then
    echo "Launching Step 7"
    if [ -e $ANALYSIS_NAME.q2pipe_step7.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step7.DONE
    fi
    $Q2P/q2pipe_step7_rarefaction_curve.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step7.DONE
    invalid_next=1
else
    echo "Step 7 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step8.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 8 ]
then
    echo "Launching Step 8"
    if [ -e $ANALYSIS_NAME.q2pipe_step8.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step8.DONE
    fi
    $Q2P/q2pipe_step8_rarefy.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step8.DONE
    invalid_next=1
else
    echo "Step 8 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step9.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 9 ]
then
    echo "Launching Step 9"
    if [ -e $ANALYSIS_NAME.q2pipe_step9.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step9.DONE
    fi

    if [ -d "$ANALYSIS_NAME.metrics_norarefaction_dn$p_perc_identity" ] && [ "$SKIP_RAREFACTION" == "true" ] || [ "$SKIP_RAREFACTION" == "both" ]
    then
        rm "$ANALYSIS_NAME.metrics_norarefaction_dn$p_perc_identity" -rf
    fi

    if [ -d "$ANALYSIS_NAME.metrics_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"" ] && [ "$SKIP_RAREFACTION" == "false" ] || [ "$SKIP_RAREFACTION" == "both" ]
    then
        rm "$ANALYSIS_NAME.metrics_rarefied_"$p_sampling_depth"_dn"$p_perc_identity"" -rf
    fi

    $Q2P/q2pipe_step9_metrics.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step9.DONE
    invalid_next=1
else
    echo "Step 9 checkpoint detected...skipping"
fi

if [ ! -e $ANALYSIS_NAME.q2pipe_step10.DONE ] || [ $invalid_next -eq 1 ] && [ $override_value -le 10 ]
then
    echo "Launching Step 10"
    if [ -e $ANALYSIS_NAME.q2pipe_step10.DONE ]
    then
        echo "Invalid checkpoint detected. Deleting..."
        rm $ANALYSIS_NAME.q2pipe_step10.DONE
    fi
    $Q2P/q2pipe_step10_export.sh $optionfile || exit_on_error
    touch $ANALYSIS_NAME.q2pipe_step10.DONE
    invalid_next=1
else
    echo "Step 10 checkpoint detected...skipping"
fi

echo "PROGRAM DONE"

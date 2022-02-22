#!/bin/bash

##################################
#                                #
# Qiime 2 Singularity Simplifier #
#       By: Patrick Gagne        #
#        October 5, 2021         #
#                                #
##################################

sourced=0
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && sourced=1

if [ $sourced -eq 0 ]
then
    echo "ERROR: This script must be sourced, not executed (source q2pipe_singularity_manual_mode optionfile)"
    exit 1
fi

optionfile=$1

if [ ! $optionfile ] || [ ! -e $optionfile ] || [ ! -r $optionfile ]
then
    echo "ERROR: you must specify a valid, accessible qiime2 optionfile"
    return 2
fi

sing_command=$( grep "SINGULARITY_COMMAND" $optionfile | sed 's/SINGULARITY_COMMAND=//g' | sed 's/"//g' )

if [ "$sing_command" == "" ]
then
    echo "ERROR: no singularity command found in optionfile"
    return 3
fi

shell_command=$( echo $sing_command | sed 's/exec/shell/g' )

alias qiime="$sing_command qiime"
alias sing="$sing_command"
alias singshell="$shell_command"

echo "Singularity aliases ready"
echo "use 'qiime' to launch qiime commands"
echo "use 'sing' to launch other commands within the qiime2 container (ex sing biom)"
echo "use 'singshell' to directly interact with the singularity container"

return 0



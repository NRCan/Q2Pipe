#!/bin/bash

manifest_file=$1
manifest_output=$2

if [ ! $1 ]
then
    echo "ERROR: no csv manifest file specified"
    echo "USAGE: $0 manifest.csv manifest_out.csv"
    exit 1
fi

if [ ! $2 ]
then
    echo "ERROR: no csv manifest output specified"
    echo "USAGE: $0 manifest.csv manifest_out.csv"
    exit 1
fi

#sed 's|.*/||'
#sed 's|\(.*\)/.*|\1|

head -n 1 $manifest_file > $manifest_output
tail -n +2 $manifest_file > .manifest_convertion.temp


while read line
do
    file_path=$( echo $line | awk -F ',' '{ print $2 }' | sed 's|\(.*\)/.*|\1|' )
    new_line=$( echo $line | sed "s;$file_path;/input;g" )
    echo $new_line >> $manifest_output
done<.manifest_convertion.temp

rm .manifest_convertion.temp


#/bin/bash

optionfile=$1

if [ ! $optionfile ] || [ ! -e $optionfile ] || [ ! -r $optionfile ]
then
    echo "ERROR: you must specify a valid, accessible qiime2 optionfile"
    exit 1
fi

if [ ! $Q2P ]
then
    echo "WARNING: Q2P environment variable not set"
    echo "This script requires this variable to work"
    echo "Setting temporary Q2P variable"
    SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    export Q2P=$SCRIPT_DIR
fi

echo "Installation path: $Q2P"
echo ""

default_param=$( grep "=" $Q2P/optionfile_q2pipe_default.txt  | grep "#" -v | awk -F'=' '{ print $1 }' | sort )
target_param=$( grep "=" $optionfile  | grep "#" -v | awk -F'=' '{ print $1 }' | sort )



surplus_param=""
for i in $target_param
do
   found=0
   for j in $default_param
   do
     if [ "$i" == "$j" ]
     then
         found=1
         break
     fi
   done
   if [ $found -eq 0 ]
   then
       surplus_param="$surplus_param $i"
   fi
done

missing_param=""
for i in $default_param
do
   found=0
   for j in $target_param
   do
     if [ "$i" == "$j" ]
     then
         found=1
         break
     fi
   done
   if [ $found -eq 0 ]
   then
       missing_param="$missing_param $i"
   fi
done

count=0
for i in $surplus_param
do
  if [ $count -eq 0 ]
  then
      let $[ count += 1 ]
      echo "These parameter are in your current optionfile but not in the default file and should be removed"
  fi
    grep "$i=" $optionfile
done

echo ""
if [ "$missing_param" == "" ]
then
    echo "This optionfile is already up-to-date for missing parameters"
    exit 0
fi
count=0
cp $optionfile $optionfile.new
for i in $missing_param
do
  if [ $count -eq 0 ]
  then
      let $[ count += 1 ]
      echo "These parameter are missing from your current optionfile, the will be added from default"
  fi
  line=$( grep -n "$i=" $Q2P/optionfile_q2pipe_default.txt )
  line_to_add=$( echo $line | awk -F':' '{ print $2 }' )
  line_number=$( echo $line | awk -F':' '{ print $1 }' )
  echo "$line_to_add"
  sed -i "$line_number i $line_to_add" $optionfile.new
done

echo ""
echo "Up-to-date optionfile ready ($optionfile.new)"


#echo $missing_param

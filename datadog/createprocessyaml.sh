#!/bin/bash

#File name is set to the file name after the location of the process.yaml file
filename=/etc/datadog-agent/conf.d/process.d/process.yaml
#filename=~/proces.yaml

#If the file doesn't exist then create the file and remove all restriction. Add first line "instances:"
if [[ ! -f $filename ]];then
 sudo touch $filename
 sudo chmod 777 $filename
 echo "instances:" >> $filename
fi

#The process.csv from appconfig is used to check what processes are going to be monitored
input=${TORQHOME}/appconfig/process.csv

#From the process.csv the 14th column(datadog) is read and if it is set to 1 the 4th column (procname) is put into the correct format to add the monitor to datadog.
cut -d "," -f4,14 "$input" | sed '1d' | while IFS=, read procname flag; do
if [[ "$flag" == "1" ]]; then
     printf -- "- name: ${procname^^}\n  search_string: ['$procname']\n  exact_match: False\n" >> $filename
fi
done
##Does setenv.sh need to be  sourced for $TORQPROCESSES to work.

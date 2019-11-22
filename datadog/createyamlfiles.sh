#!/bin/bash

#File name is set to the file name after the location of the process.yaml file
#filename1=/etc/datadog-agent/conf.d/process.d/process.yaml
filename1=~/process.yaml

#If the file doesn't exist then create the file and remove all restriction. Add first line "instances:"
if [[ ! -f $filename1 ]];then
 sudo touch $filename1
 sudo chmod 777 $filename1
 echo "instances:" >> $filename1
fi

#The process.csv from appconfig is used to check what processes are going to be monitored
input=${TORQHOME}/appconfig/process.csv

#From the process.csv the 14th column(datadog) is read and if it is set to 1 the 4th column (procname) is put into the correct format to add the monitor to datadog.
cut -d "," -f4,14 "$input" | sed '1d' | while IFS=, read procname flag; do
if [[ "$flag" == "1" ]]; then
     printf -- "- name: ${procname^^}\n  search_string: ['$procname']\n  exact_match: False\n" >> $filename1
fi
done

#Filename is set to be in correct directory
#filename2=/etc/datadog-agent/datadog.yaml
filename2=~/datadog.yaml

#If the file doesn't exist, make file and remove restrictions. Add the "echo" lines and save to file.
touch $filename2
sudo chmod 777 $filename2
sudo echo "use_dogstatsd: true
dogstatsd_port: 8125

process_config:
 enabled: \"true\"" >> $filename2


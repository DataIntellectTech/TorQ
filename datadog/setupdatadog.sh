#!/bin/bash

#Set the enviroment for TORQHOME
cd ..
source setenv.sh

if [ -z $1 ]; then
  echo "no argument provided; defaulting dogstatsd_port to 8125"
  dogstatsd_port=8125
else
  dogstatsd_port=$1
fi

ddconfigfile=${KDBAPPCONFIG}/ddconfig.txt
echo "dogstatsd_port:"$dogstatsd_port > $ddconfigfile

#File path of the process.yaml file
filename1=/etc/datadog-agent/conf.d/process.d/process.yaml

#The process.csv is used to check what processes are to be added to the process.yaml file
input=${KDBAPPCONFIG}/process.csv

#If file doesn't exist create it and remove all restriction. Add first line "instances:". If datadog column exists in process.csv take processes marked for monitoring
if [[ ! -f $filename1 ]];then
  sudo touch $filename1
  sudo chmod 777 $filename1
  echo "instances:" >> $filename1
  echo "Process.yaml file created"
  if grep -q "datadog" $input ; then
    cut -d "," -f4,14 "$input" | sed '1d' | while IFS=, read procname flag; do
      if [[ "$flag" == "1" ]]; then
        printf -- "- name: ${procname^^}\n  search_string: ['$procname']\n  exact_match: False\n" >> $filename1
        echo "$procname has been added to process.yaml"
      fi
    done
    echo "All processes to be monitored added to process.yaml file from $input"
  else 
#If the datadog column is not present all processes are added
    cut -d "," -f4 "$input" | sed '1d' | while read line; do
      printf -- "- name: `echo "$line" | tr a-z A-Z`\n  search_string: ['$line']\n  exact_match: False\n" >> $filename1
    done
    echo "All processes added to process.yaml from $input"  
  fi
else
  echo "$input already exists, no changes were made to avoid duplication."
fi

#File path of the datadog.yaml file
filename2=/etc/datadog-agent/datadog.yaml

#If file doesn't exist make it and remove restrictions. Add necessary lines and save file.
sudo touch $filename2
sudo chmod 777 $filename2
if grep -qFx "use_dogstatsd: true" $filename2 ; then
  echo "Datadog.yaml file has port enabled, no changes were made to avoid duplication."
else
  sudo echo "use_dogstatsd: true
dogstatsd_port: $dogstatsd_port

process_config:
 enabled: \"true\"" >> $filename2
  echo "Datadog.yaml file is now enabled to send data through port $dogstatsd_port"
fi

#Create the crontab to run runchecks.sh at specified intervals.
echo "Creating crontab if it doesn't already exist"
crontab -l | grep -q 'runchecks'  && echo 'Crontab already exists.' || (crontab -l 2>/dev/null; echo "PATH=$PATH"; echo " * * * * * cd $TORQHOME/; . $TORQHOME/datadog/runchecks.sh") | crontab -

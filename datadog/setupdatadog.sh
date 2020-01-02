#!/bin/bash

echo dogstatsd_port is set to $DOGSTATSD_PORT in setenv.sh.

#if [ -z $1 ]; then
#  echo "no argument provided; defaulting dogstatsd_port to 8125"
#  dogstatsd_port=8125
#else
#  dogstatsd_port=$1
#fi

dgconfigfile=${KDBAPPCONFIG}/dgconfig.txt
echo "dogstatsd_port:"$DOGSTATSD_PORT > $dgconfigfile

#File path of the process.yaml file
processfile=/etc/datadog-agent/conf.d/process.d/process.yaml

#The process.csv is used to check what processes are to be added to the process.yaml file
input=${KDBAPPCONFIG}/process.csv

#If file doesn't exist create it and remove all restriction. Add first line "instances:". If datadog column exists in process.csv take processes marked for monitoring
if [[ ! -f $processfile ]];then
  sudo touch $processfile
  sudo chmod 777 $processfile
  echo "instances:" >> $processfile
  echo "process.yaml file created"
  if grep -q "datadog" $input ; then
    cut -d "," -f4,14 "$input" | sed '1d' | while IFS=, read procname flag; do
      if [[ "$flag" == "1" ]]; then
        printf -- "- name: ${procname^^}\n  search_string: ['$procname']\n  exact_match: False\n" >> $processfile
        echo "$procname has been added to process.yaml"
      fi
    done
    echo "All processes to be monitored added to process.yaml file from $input"
  else 
#If the datadog column is not present all processes are added
    cut -d "," -f4 "$input" | sed '1d' | while read line; do
      printf -- "- name: `echo "$line" | tr a-z A-Z`\n  search_string: ['$line']\n  exact_match: False\n" >> $processfile
    done
    echo "All processes added to process.yaml from $input"  
  fi
else
  echo "$processfile already exists, no changes were made to avoid duplication."
fi

#File path of the datadog.yaml file
datadogfile=/etc/datadog-agent/datadog.yaml

#If file doesn't exist make it and remove restrictions. Add necessary lines and save file.
sudo touch $datadogfile
sudo chmod 777 $datadogfile
if grep -qFx "use_dogstatsd: true" $datadogfile ; then
  echo "datadog.yaml file has port enabled, no changes were made to avoid duplication."
else
  sudo echo "use_dogstatsd: true
dogstatsd_port: $DOGSTATSD_PORT

process_config:
 enabled: \"true\"" >> $datadogfile
  echo "Datadog.yaml file is now enabled to send data through port $DOGSTATSD_PORT"
fi

#Create the crontab to run runchecks.sh at specified intervals.
while true;do
  read -p "Do you wish to install a crontab? [y/N]" yn
  case $yn in
    [Yy]* ) crontab -l | grep -q 'runchecks'  && echo 'Crontab already exists.' || (crontab -l 2>/dev/null; echo "PATH=$PATH"; echo " * * * * * cd $TORQHOME/; . $TORQHOME/datadog/runchecks.sh") | crontab -; echo "Crontab installed" ; break;;
    [Nn]* ) echo "Crontab not installed, please set up check scheduling." ; break;;
    * ) echo "Please answer y or n.";;
  esac
done


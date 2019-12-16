#!/bin/bash

#Set the enviroment so TORQHOME is correct
cd ..
source setenv.sh

if [ -z $1 ]; then
	echo "no argument provided; defaulting dogstatsd_port to 8125"
	dogstatsd_port=8125
else
	dogstatsd_port=$1
fi

echo ${TORQHOME}
ddconfigfile=${TORQHOME}/appconfig/ddconfig.txt
echo "dogstatsd_port:"$dogstatsd_port > $ddconfigfile

#File name is set to the file name after the location of the process.yaml file
filename1=/etc/datadog-agent/conf.d/process.d/process.yaml
#filename1=~/process.yaml

#The process.csv from appconfig is used to check what processes are going to be monitored
input=${TORQHOME}/appconfig/process.csv

#If the file doesn't exist then create the file and remove all restriction. Add first line "instances:"
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

#Filename is set to be in correct directory
filename2=/etc/datadog-agent/datadog.yaml
#filename2=./datadog.yaml

#If the file doesn't exist, make file and remove restrictions. Add the "echo" lines and save to file.
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

#Creating the crontab to run and send check information
echo "Creating crontab if it doesn't already exist"
crontab -l | grep -q 'runchecks'  && echo 'Crontab already exists.' || (crontab -l 2>/dev/null; echo " * * * * * cd $TORQHOME/; . $TORQHOME/datadog/runchecks.sh") | crontab - 


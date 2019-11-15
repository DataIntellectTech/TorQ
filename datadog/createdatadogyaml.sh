#!/bin/bash

#Filename is set to be in correct directory
filename=/etc/datadog-agent/datadog.yaml
#filename=~/datadog.yaml

#If the file doesn't exist, make file and remove restrictions. Add the "echo" lines and save to file.
if [[ ! -f $filename ]];then
 sudo touch $filename
 sudo chmod 777 $filename
 sudo echo "api_key: a7d735c8f7cffdb56f1da828add7956b

use_dogstatsd: true
dogstatsd_port: 8125

process_config:
 enabled: \"true\"" >> $filename
fi
#Need to be able to find api_key somehow, or enter it here manually.

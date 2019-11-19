#!/bin/bash

#Filename is set to be in correct directory
filename=/etc/datadog-agent/datadog.yaml

#Remove file restrictions add the "echo" lines and save to file.
sudo chmod 777 $filename
sudo echo "use_dogstatsd: true
dogstatsd_port: 8125

process_config:
 enabled: \"true\"" >> $filename

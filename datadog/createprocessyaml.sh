#!/bin/bash
filename=/etc/datadog-agent/conf.d/process.d/process.yaml
#filename=~/proces.yaml

if [[ ! -f $filename ]];then
 sudo touch $filename
 sudo chmod 777 $filename
 echo "instances:" >> $filename
fi

input=$TORQPROCESSES

cut -d "," -f4 $TORQPROCESSES | sed '1d' | while read line;
do
printf -- "- name: `echo "$line" | tr a-z A-Z`\n  search_string: ['$line']\n  exact_match: False\n" >> $filename
done

##need to have setenv sourced for $TORQPROCESSES to work.

#!/bin/bash
#filename=/etc/datadog-agent/conf.d/process.d/proces.yaml
filename=~/proces.yaml
if [[ ! -f $filename ]];then
   touch $filename
   echo "instances:" >> $filename
fi

#input=~/process.txt

#for x in ~/processes.txt
#do
#Cap= echo "$x" | tr a-z A-Z
#record=
#echo "-  name: $Cap 
#         search_string: ['$x']
#         exact_match: False"
#
#done

cat ~/processes.txt | while read line;
do
#Cap= echo "$line" | tr a-z A-Z
printf -- "- name: `echo "$line" | tr a-z A-Z`\n  search_string: ['$line']\n  exact_match: False\n" >> $filename
done

#instances:
#- name: DISCOVERY1
#  search_string: ['discovery1']
#  exact_match: False


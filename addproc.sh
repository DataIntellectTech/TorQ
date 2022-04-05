#!/bin/bash

#this script takes two argument from the cmd line: procname and an integer
#it replicates the process from first argument and names it using second
#all new processes are started automatically to avoid port number overlap upon running the script multiple times without starting the new procs first
#new processes are written to customprocess.csv which also contains the original processes 
#after process replication a summmary of all procs is provided
#stop any process replica using: 
#bash {TORQHOME}/torq.sh stop <PROCNAME/ALL> -csv ${KDBAPPCONFIG}/customprocess.csv

#source the relevant setenv.sh
source setenv.sh

#input procname from cmd line
inputprocname=$1

#input wanted name suffix
suffix=$2

#work out new procname based on second and third arg provided
newprocname="$inputprocname"."$suffix"
newprocname1="$inputprocname"\."$suffix"

#determine port number increment based on number of lines in the process.csv
#if that port is already in use, increment by 1 till succesful
portnum="$(wc -l < ${KDBAPPCONFIG}/process.csv)"
while [ "$(netstat -an | grep "$((${KDBBASEPORT}+$portnum))" | grep -i listen)" != "" ]
do
	((portnum++))
done

#get all procnames from process.csv
PROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/process.csv | awk -F',' '{print $4}')"

#get all procnames from customprocess.csv
CUSTOMPROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/customprocess.csv | awk -F',' '{print $4}')"

#check for correct argument number and content:
#check if inputed procname matches a procname in process.csv
#check if second argument is an integer
#check if new procname is already in use
#if any of the arguments invalid, print the user guide, else proceed with replication
if [ "$(echo $PROCNAMES | grep -w $inputprocname)" == "" ] || [ $# != 2 ] || [[ ! "$suffix" =~ ^[0-9]+$ ]] || [ "$(echo $PROCNAMES | grep -w $newprocname)" != "" ] || [ "$(echo $CUSTOMPROCNAMES | grep -w $newprocname)" != "" ] ; then
	echo -e 'Error: invalid arguments.\n\nUse valid procname as first argument, e.g. rdb1.\nUse positive integer as second argument.\nNew procname cannot be identical to already exsting one.\n\n'
	echo 'Valid procnames: ' $PROCNAMES
	echo -e '\nProcnames in customprocess.csv already in use: ' $CUSTOMPROCNAMES
else
       
#use the inputed procname to replicate the process and append to it
#calculated port number and provided suffix will be used in the replicated process name
#replicated process starts automatically using customprocess.csv in -csv flag
#run summary of all processes in customprocess.csv
	grep $inputprocname ${KDBAPPCONFIG}/process.csv | awk -F',' -vOFS=',' '{ $2 = "{KDBBASEPORT}+" '"$portnum"'; $4 ="'$newprocname'" }1' >> ${KDBAPPCONFIG}/customprocess.csv
    	echo "$inputprocname replicated as $newprocname" 
	bash torq.sh start $newprocname 
	bash torq.sh summary
fi

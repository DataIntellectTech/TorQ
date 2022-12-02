#!/bin/bash

#before running the script ensure the stack is running
#this script takes an existing procname as an argument to determine what process to replicate
#procname is configured automatically based on the last process replica name
#all new processes are started automatically to avoid port number overlap upon running the script multiple times without starting the new procs first
#new processes are written to customprocess.csv which also contains the original processes from process.csv (this may have to be done manually)
#after process replication a summmary of all procs is provided
#stop any process replica using: 
#bash {TORQHOME}/torq.sh stop <PROCNAME/ALL> -csv ${KDBAPPCONFIG}/customprocess.csv
#to automatize the process summary/start/stop using torq.sh for processes in both process.csv and customprocess.csv do:
# 	-copy all contents of process.csv into customprocess.csv before running the script
#	-configure ${TORQPROCESSES} in setenv.sh to point to customprocess.csv 

#input procname from cmd line
inputprocname=$1

#get all procnames from process.csv
PROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/process.csv | awk -F',' '{print $4}')"

#get all procnames from customprocess.csv
CUSTOMPROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/customprocess.csv | awk -F',' '{print $4}')"

#check for correct argument number and content:
#check number of arguments is greater than 1
#check if number of arguments is lower than one
#check if inputed procname matches a procname in process.csv
if [ $# -gt 1 ] ; then
        echo -e '\nToo many arguments.'
elif [ $# -lt 1 ] ; then
        echo -e '\nProcname needed. Use: \n ' $PROCNAMES
elif [ $# -eq 1 ] ; then
	if [ "$(echo $PROCNAMES | grep -w $inputprocname)" == "" ] ; then
		echo -e '\nUnavailable procname. Use: \n' $PROCNAMES
	else

#get the last replica of inputed procname
		var=$(bash ${TORQHOME}/torq.sh procs -csv ${KDBAPPCONFIG}/customprocess.csv | grep $inputprocname | tail -n 1)

#work out new procname based var
		if [ `echo $var | grep -P -o '\d' | wc -l` -lt 2 ] ; then
			next=2
		else
			next=$((${var: -1} + 1))
		fi
		newprocname="$inputprocname"."$next"

#determine port number increment based on number of lines in the process.csv
#if that port is already in use, increment by 1 till succesful
		portnum="$(wc -l < ${KDBAPPCONFIG}/process.csv)"
		while [ "$(netstat -an | grep "$((${KDBBASEPORT}+$portnum))" | grep -i listen)" != "" ]
		do
			((portnum++))
		done

#use the inputed procname to determine what process to replicate:
#use configured port number and process name 
#add new process to customprocess.csv
#starts the replicated process automatically using customprocess.csv in the -csv flag
#run summary of all processes in customprocess.csv
		grep $inputprocname ${KDBAPPCONFIG}/process.csv | awk -F',' -vOFS=',' '{ $2 = "{KDBBASEPORT}+" '"$portnum"'; $4 ="'$newprocname'" }1' >> ${KDBAPPCONFIG}/customprocess.csv
    		echo "$inputprocname replicated as $newprocname" 
		bash ${TORQHOME}/torq.sh start $newprocname -csv ${KDBAPPCONFIG}/customprocess.csv
		bash ${TORQHOME}/torq.sh summary -csv ${KDBAPPCONFIG}/customprocess.csv
	fi
fi

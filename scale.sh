#!/bin/bash

usage() { echo "Usage: $0 [-u procname] or [-d procname]"; exit 1; }

#input procname from cmd line
inputprocname=$2
#get all procnames from process.csv
PROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/process.csv | awk -F',' '{print $4}')"
#get all procnames from customprocess.csv
CUSTOMPROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/customprocess.csv | awk -F',' '{print $4}')"

if [ $# -gt 2 ] ; then
        echo -e '\nToo many arguments.'
elif [ $# -eq 1 ] ; then
	if [[ "$1" == "-"* ]]; then
		echo -e '\nProcname needed. Use: \n ' $CUSTOMPROCNAMES
	else
		usage
	fi
elif [ $# -eq 2 ] ; then
	while getopts "ud" option;do
		case ${option} in
			u)
#check for correct argument number and content:
#check number of arguments is greater than 1
#check if number of arguments is lower than one
#check if inputed procname matches a procname in process.csv
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
				;;
			d)
				if [ "$(echo $CUSTOMPROCNAMES | grep -w $inputprocname)" ] ; then
                			echo -e 'Shutting down process now'
					bash ${TORQHOME}/torq.sh stop $inputprocname -csv ${KDBAPPCONFIG}/customprocess.csv
					cp ${KDBAPPCONFIG}/customprocess.csv ${KDBAPPCONFIG}/customprocessCopy.csv
					grep -v "$inputprocname" ${KDBAPPCONFIG}/customprocessCopy.csv >| ${KDBAPPCONFIG}/customprocess.csv
				else
					echo 'Process name does not match, try again'
				fi
				;;
			*)
				usage
				;;
		esac
	done
else 
	usage
fi

#!/bin/bash

#source the relevant setenv.sh
source setenv.sh

#get all procnames from process.csv
PROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/process.csv | awk -F',' '{print $4}')"

#input procname from cmd line
inputprocname=$1

#get all procnames from customprocess.csv
CUSTOMPROCNAMES="$(sed '1d' ${KDBAPPCONFIG}/customprocess.csv | awk -F',' '{print $4}')"
#echo '***** LOOK HERE' $CUSTOMPROCNAMES '****'
cp ${KDBAPPCONFIG}/customprocess.csv ${KDBAPPCONFIG}/customprocessCopy.csv

#check for correct argument number and content:
#check number of arguments is greater than 1
#check if number of arguments is lower than one
#check if inputed procname matches a procname in process.csv

if [ $# -gt 1 ] ; then
        echo -e '\nToo many arguments.'
elif [ $# -lt 1 ] ; then
        echo -e '\nProcname needed. Use: \n ' $CUSTOMPROCNAMES
elif [ $# -eq 1 ] ; then
        if [ "$(echo $CUSTOMPROCNAMES | grep -w $inputprocname)" ] ; then
                echo -e 'Shutting down process now'

                bash torq.sh stop $inputprocname -csv ${KDBAPPCONFIG}/customprocessCopy.csv
                grep -v "$inputprocname" ${KDBAPPCONFIG}/customprocessCopy.csv >| ${KDBAPPCONFIG}/customprocess.csv
                #bash ./torq.sh stop $inputprocname
        else
                echo 'Process name does not match, try again'
        fi

fi

#remove process from customprocess.csv
#echo $CUSTOMPROCNAMES | grep -w $inputprocname | sed -i $inputprocname ${KDBAPPCONFIG}/customprocess.csv
#sed -i '/$inputprocname/d' ${KDBAPPCONFIG}/customprocess.csv
#grep -v "$inputprocname" ${KDBAPPCONFIG}/customprocessCopy.csv >| ${KDBAPPCONFIG}/customprocess.csv

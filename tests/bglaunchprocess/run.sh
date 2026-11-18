#!/bin/bash

#path to test directory
testpath=${KDBTESTS}/bglaunchprocess/

#remove any port files left by an earlier run (written when discovery is off: see settings.q)
rm -f ${KDBLOG}/bglaunchprocess_*.port

#start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/process.csv

#Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
	-proctype test -procname test1 \
	-test ${testpath} \
	-load ${TORQHOME}/code/common/bglaunchutils.q ${testpath}/settings.q     \
	-procfile ${testpath}/process.csv -debug

#Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv
rm -f ${KDBLOG}/bglaunchprocess_*.port

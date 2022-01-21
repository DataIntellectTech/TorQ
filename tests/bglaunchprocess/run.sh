#!/bin/bash

#path to test directory
testpath=${KDBTESTS}/bglaunchprocess/

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

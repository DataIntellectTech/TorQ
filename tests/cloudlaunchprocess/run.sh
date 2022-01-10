#!/bin/bash

#path to test directory
testpath=${KDBTESTS}/cloudlaunchprocess

#start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/process.csv

#Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
	-proctype test -procname rdb1 \
	-test ${testpath} \
	-load ${TORQHOME}/code/common/cloudutils.q ${testpath}/settings.q     \
	-procfile ${testpath}/process.csv -debug

#Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv

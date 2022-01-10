#!/bin/bash

#path to test directory
testpath=${KDBTESTS}/lproctests

#start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/lprocprocess.csv

#Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
	-proctype test -procname hdb1 \
	-test ${testpath} \
	-load ${TORQHOME}/code/common/cloudutils.q ${testpath}/settings.q     \
	-procfile ${testpath}/lprocprocess.csv -debug

#Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/lprocprocess.csv

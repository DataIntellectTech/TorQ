#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

#Set up the test env with data
#path to test directory
testpath=${KDBTESTS}/schemas

#start procs
${TORQHOME}/torq.sh start discovery1 rdb1 stp1 hdb1 wdb1 -csv ${testpath}/process.csv
${TORQHOME}/torq.sh summary -csv ${testpath}/process.csv

#Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
	-proctype test -procname test1 \
	-load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q ${testpath}/insert_data.q     \
	-procfile ${testpath}/process.csv -quiet

${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv

# Do the tests
#start procs
${TORQHOME}/torq.sh start discovery1 rdb1 stp1 hdb1 wdb1 -csv ${testpath}/process.csv

#Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
	-proctype test -procname test1 \
	-test ${testpath} \
	-load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q     \
	-procfile ${testpath}/process.csv -debug

#Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv

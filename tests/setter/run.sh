#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/setter

# Procs setter needs - the gateway queries the rdb and a one-day test hdb
# testhdb1 starts before the gateway so the gateway finds it, on an empty folder the tests fill in and reload
procs="testdiscovery1 teststp1 testrdb1 testhdb1 testgateway1"
mkdir -p ${testpath}/tmphdb

# Start procs
${TORQHOME}/torq.sh start ${procs} -csv ${testpath}/process.csv

# Start setter once the others are up - it only waits ~3 seconds for the gateway when it loads
sleep 5
${TORQHOME}/torq.sh start testsetter1 -csv ${testpath}/process.csv

# Start test proc
${RLWRAP} q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/setter/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  $debug $stop $write $quiet

# Shut down procs and remove anything the tests wrote to disk
${TORQHOME}/torq.sh stop ${procs} testsetter1 -csv ${testpath}/process.csv
rm -rf ${testpath}/tmpcache ${testpath}/tmptplogs ${testpath}/tmphdb

#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/merge/wdb

mkdir ${testpath}/testhdb

# Start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/config/process.csv

# Start test proc
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q \
 -proctype test -procname test1 \
 -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q ${testpath}/mockdata.q \
 -test ${testpath}/tests \
 -testresults ${KDBTESTS}/merge/wdb/results/ \
 -runtime $run \
 -procfile ${testpath}/config/process.csv \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/config/process.csv

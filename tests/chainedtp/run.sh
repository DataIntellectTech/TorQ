#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/chainedtp

# Start procs
${TORQHOME}/torq.sh start discovery1 tp1 ctp1 rdb1 -csv ${testpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${testpath}/results/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

# Stop procs
${TORQHOME}/torq.sh stop rdb1 ctp2 tp1 discovery1 -csv ${testpath}/process.csv

#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/chainedeodlognone

# Start procs
${TORQHOME}/torq.sh start discovery1 stptest1 sctptest1 rdb1 -csv ${testpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  $debug $stop $quiet

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stptest1 sctptest1 rdb1 -csv ${testpath}/process.csv

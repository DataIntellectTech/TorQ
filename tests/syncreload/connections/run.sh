#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/syncreload/connections

# Start procs
${TORQHOME}/torq.sh start stp1 hdb1 rdb1 rdb2 wdb1 -csv ${testpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/stp/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop stp1 hdb1 rdb1 rdb2 wdb1 -csv ${testpath}/process.csv

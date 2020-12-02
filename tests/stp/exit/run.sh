#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/exit

${TORQHOME}/torq.sh start discovery1 stpex -csv ${testpath}/process.csv

/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/stp/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  $debug $stop $write $quiet

${TORQHOME}/torq.sh stop discovery1 stpex -csv ${testpath}/process.csv
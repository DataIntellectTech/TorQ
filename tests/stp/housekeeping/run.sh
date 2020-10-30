#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/housekeeping

# Start procs
${TORQHOME}/torq.sh start discovery1 housekeeping1

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/stp/results/ \
  -runtime $run \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 housekeeping1
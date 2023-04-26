#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/batching

# Start up procs
${TORQHOME}/torq.sh start discovery1 stp1 rdb1

# Start up test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -schemafile ${TORQHOME}/database.q \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/stp/results/ \
  -runtime $run \
  $debug $stop $write $quiet

# Close other procs
${TORQHOME}/torq.sh stop discovery1 stp1 rdb1
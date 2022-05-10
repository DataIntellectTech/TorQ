#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

#directory path to tests
testpath=${KDBTESTS}/gateway

/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype gateway -procname gateway1 \
  -test ${testpath} \
  -testresults ${testpath}/results/ \
  $quiet $write $debug

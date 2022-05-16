#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

#directory path to tests
testpath=${KDBTESTS}/gateway

${RLWRAP} ${QCMD} ${TORQHOME}/torq.q \
  -proctype gateway -procname gateway1 \
  -test ${testpath} \
  -testresults ${testpath}/results/ \
  $quiet $stop $write $debug

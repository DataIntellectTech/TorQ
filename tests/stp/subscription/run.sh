#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/subscription

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 rdball rdbsymfilt rdbcomplexfilt -csv ${testpath}/process.csv

# Start test proc
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/stp/results/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stp1 rdball rdbsymfilt rdbcomplexfilt -csv ${testpath}/process.csv

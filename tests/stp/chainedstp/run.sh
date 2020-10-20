#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/chainedstp

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 sctp1 -csv ${KDBTESTS}/stp/chainedstp/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stp1 sctp1 rdball rdbsymfilt rdbcomplexfilt -csv ${KDBTESTS}/stp/chainedstp/process.csv

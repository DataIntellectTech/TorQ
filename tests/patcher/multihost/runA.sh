#!/bin/bash

# Execute runB.sh script on secondary host, then execute runA.sh on primary to run test

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/patcher/multihost

# Load host ips
source ${testpath}/hostnames.sh

# Start procs
${TORQHOME}/torq.sh start discovery1 rdb1 stp1 patcher1 -csv ${testpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/patcher/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  $debug $stop $write $quiet


# Shut down procs
${TORQHOME}/torq.sh stop discovery1 rdb1 stp1 patcher1 -csv ${testpath}/process.csv

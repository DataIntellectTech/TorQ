#!/bin/bash

cd $HOME/TorQ/deploy/TorQ/latest
source setenv.sh

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
export testpath=${KDBTESTS}/stp/stripe
export perfpath=${testpath}/performance

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 rdb1 rdb2 rdb3 rdb4 -csv ${testpath}/process.csv

# Start test proc
QCMD='taskset -c 0,1 /usr/bin/rlwrap q'
${QCMD} ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/stp/results/stripe/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  -write
  #$debug $stop $write $quiet

# Shut down stp1
${TORQHOME}/torq.sh stop stp1 -csv ${testpath}/process.csv

# Performance tests
# Start stpperf
${TORQHOME}/torq.sh start stpperf -csv ${testpath}/process.csv
# Procs will stop automatically once tests are completed
echo Performance tests are running in the background

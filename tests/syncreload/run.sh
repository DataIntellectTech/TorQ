#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=/home/creid/devTorQ/bin/syncreload

# Start procs
bin/torq.sh start discovery1 stp1 hdb1 rdb1 rdb2 wdb1 gateway1 -csv ${testpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/syncreload/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  $debug $stop $write $quiet

# Shut down procs
bin/torq.sh stop discovery1 stp1 hdb1 rdb1 rdb2 wdb1 gateway1 -csv ${testpath}/process.csv

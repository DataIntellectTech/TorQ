#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/dataaccess/checkquery

# Start procs
${TORQHOME}/torq.sh start discovery1 dailyhdb1 monthlyhdb1 yearlyhdb1 dailyrdb1 monthlyrdb1 yearlyrdb1 -csv ${testpath}/config/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/../settings.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/dataaccess/results/ \
  -runtime $run \
  -procfile ${testpath}/config/process.csv \
  -dataaccess ${testpath}/config/tableproperties.csv \
  $debug $stop $write $quiet

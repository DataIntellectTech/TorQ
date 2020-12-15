#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/dataaccess/checkinputs

# Start procs
${TORQHOME}/torq.sh start discovery1

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype rdb -procname dailyrdb1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/../settings.q ${testpath}/settings.q ${testpath}/../mockdata.q \
  -testresults ${KDBTESTS}/dataaccess/results/ \
  -runtime $run \
  -procfile ${testpath}/config/process.csv \
  -dataaccess ${testpath}/config/tableproperties.csv \
  $debug $stop $write $quiet

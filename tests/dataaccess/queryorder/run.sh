#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to query order test directory
testpath=${KDBTESTS}/dataaccess/queryorder

# Start test proc
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q \
  -proctype rdb -procname dailyrdb1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/../settings.q ${testpath}/settings.q ${testpath}/../mockdata.q ${testpath}/hdb \
  -testresults ${KDBTESTS}/dataaccess/results/ \
  -runtime $run \
  -procfile ${testpath}/config/process.csv \
  -dataaccess ${testpath}/config/tableproperties.csv \
  $debug $stop $write $quiet

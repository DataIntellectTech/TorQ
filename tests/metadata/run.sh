#!/bin/bash

# Handle command-line arguments
source ${KDBTESTS}/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/metadata

# Start procs
${TORQHOME}/../devTorQCloud/torq.sh start all -procfile ${testpath}/process.csv

# Start test proc
${QCMD} ${TORQHOME}/torq.q -e 1 \
  -proctype rdb -procname rdb1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q ${TORQHOME}/code/processes/rdb.q \
  -testresults ${KDBTESTS}/metadata/results/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  -.ds.datastripe 1 -segid 1 \
  $debug $stop $write $quiet

# Stop procs
${TORQHOME}/../devTorQCloud/torq.sh stop all -procfile ${testpath}/process.csv

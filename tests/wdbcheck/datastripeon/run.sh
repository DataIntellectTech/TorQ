#!/bin/bash

source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/wdbcheck/datastripeon

${TORQHOME}/../devTorQCloud/torq.sh start all -procfile ${testpath}/process.csv

# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -proctype wdb -procname wdb1 \
  -procfile ${testpath}/process.csv \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q \
  -runtime $run \
  -testresults ${testpath}/results \
  -debug

${TORQHOME}/../devTorQCloud/torq.sh stop all -procfile ${testpath}/process.csv

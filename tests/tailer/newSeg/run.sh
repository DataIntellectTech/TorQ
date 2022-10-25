#!/bin/bash

source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/tailer/newSeg

# Start procs
${TORQHOME}/../devTorQCloud/torq.sh start all -procfile ${testpath}/process.csv

# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -proctype tailer -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/tailer/newSeg/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

${TORQHOME}/../devTorQCloud/torq.sh stop all -procfile ${testpath}/process.csv

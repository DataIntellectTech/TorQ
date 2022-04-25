#!/bin/bash

# Path to test directory
testpath=${KDBTESTS}/tailer/access

# Start procs
${TORQHOME}/torq.sh start all -procfile ${testpath}/process.csv


# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -proctype wdb -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q \
  -testresults ${KDBTESTS}/tailer/access/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

#$QCMD ${TORQHOME}/torq.q \
#      -proctype wdb \
#      -procname wdb1 -test ${KDBTESTS}/tailer/savedown/ \
#      -procfile ${KDBTESTS}/tailer/savedown/process.csv \
#      -load ${KDBCODE}/processes/wdb.q -debug \

${TORQHOME}/torq.sh stop all -procfile ${testpath}/process.csv

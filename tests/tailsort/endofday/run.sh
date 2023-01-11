#!/bin/bash

source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/tailsort/endofday
KDBTAIL=${testpath}/taildir
KDBHDB=${testpath}/hdb
export QCMD="taskset -c 0,1 /usr/bin/rlwrap q"

# Start procs
${TORQHOME}/../devTorQCloud/torq.sh start all -procfile ${testpath}/process.csv


# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -proctype tailer -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/tailsort/endofday/logs/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

${TORQHOME}/../devTorQCloud/torq.sh stop all -procfile ${testpath}/process.csv

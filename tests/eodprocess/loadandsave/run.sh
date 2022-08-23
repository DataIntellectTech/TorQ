#!/bin/bash

source ${KDBTESTS}/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/eodprocess/loadandsave

# Start procs
${TORQHOME}/../deploy/torq.sh start all -procfile ${testpath}/process.csv


# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -load ${KDBCODE}/processes/eodprocess.q \
  -proctype eodprocess -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/eodprocess/loadandsave/results \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

#$QCMD ${TORQHOME}/torq.q \
#      -proctype wdb \
#      -procname wdb1 -test ${KDBTESTS}/tailer/savedown/ \
#      -procfile ${KDBTESTS}/tailer/savedown/process.csv \
#      -load ${KDBCODE}/processes/wdb.q -debug \

${TORQHOME}/../deploy/torq.sh stop all -procfile ${testpath}/process.csv

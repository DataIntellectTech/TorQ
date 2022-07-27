#!/bin/bash

source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/datastore

# Start procs
${TORQHOME}/../deploy/torq.sh start all -procfile ${testpath}/process.csv

# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -proctype rdb -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q ${KDBCODE}/processes/rdb.q \
  -testresults ${KDBTESTS}/datastore \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  -segid 1 \
  $debug $stop $write $quiet

#$QCMD ${TORQHOME}/torq.q \
#      -proctype wdb \
#      -procname wdb1 -test ${KDBTESTS}/tailer/savedown/ \
#      -procfile ${KDBTESTS}/tailer/savedown/process.csv \
#      -load ${KDBCODE}/processes/wdb.q -debug \

${TORQHOME}/../deploy/torq.sh stop all -procfile ${testpath}/process.csv

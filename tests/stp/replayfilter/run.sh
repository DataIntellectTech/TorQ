#!/bin/bash

testpath=${TORQHOME}/tests/stp/replayfilter

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 -csv ${testpath}/process.csv

# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -proctype rdb -procname rdb1 \
  -segid 1 -.ds.datastripe 0b \
  -procfile ${testpath}/process.csv \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${KDBCODE}/processes/rdb.q ${testpath}/settings.q \
  -procfile ${testpath}/process.csv -debug

# Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv

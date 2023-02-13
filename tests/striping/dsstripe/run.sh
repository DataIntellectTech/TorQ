#!/bin/bash

source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/striping/dsstripe

${TORQHOME}/../devTorQCloud/torq.sh start all -procfile ${testpath}/process.csv

# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -load ${KDBCODE}/processes/rdb.q \
  -proctype rdb -procname rdb1 \
  -procfile ${testpath}/process.csv \
  -test ${testpath} \
  -extras -segid 1 \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -runtime $run \
  -testresults ${testpath}/results \
  $debug $stop $write $quiet

${TORQHOME}/../devTorQCloud/torq.sh stop all -procfile ${testpath}/process.csv

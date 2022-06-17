#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/merge/tplogreplay

mkdir ${testpath}/testhdb
mkdir ${testpath}/tempmergedir

# Start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/process.csv

# Start test proc
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q \
 -proctype tickerlogreplay -procname tplogreplay1 \
 -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q ${KDBCODE}/processes/tickerlogreplay.q\
 -test ${testpath}/tests \
 -testresults ${KDBTESTS}/merge/tplogreplay/results/ \
 -.replay.hdbdir ${testpath}/testhdb \
 -.replay.schemafile ${testpath}/database.q \
 -.replay.tplogdir ${testpath}/testlogs \
 -p 45590 \
 -runtime $run \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv

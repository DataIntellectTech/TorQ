#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/wdb/intpartbyenum

# Make temporary HDB directory
mkdir -p ${testpath}/temphdb

# Start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/process.csv

# Start test proc
${RLWRAP} q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${testpath}/results/ \
  -runtime $run \
  -procfile ${testpath}/process.csv \
  $debug $stop $write $quiet

# Shut down procs
${TORQHOME}/torq.sh stop all -force -csv ${testpath}/process.csv

# Remove temporary WDB and HDB directories
rm -r ${testpath}/tempwdb
rm -r ${testpath}/temphdb

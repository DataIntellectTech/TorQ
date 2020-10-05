#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 -csv ${KDBTESTS}/stp/wdb/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/wdb \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/wdb/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -runtime $1 \
  -procfile ${KDBTESTS}/stp/wdb/process.csv \
  -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 -csv ${KDBTESTS}/stp/wdb/process.csv
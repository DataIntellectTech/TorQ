#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 rdb1 stp1 -csv ${KDBTESTS}/stp/eod/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/eod \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/eod/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -procfile ${KDBTESTS}/stp/eod/process.csv \
  -runtime $1 \
  -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 rdb1 stp1 -csv ${KDBTESTS}/stp/eod/process.csv

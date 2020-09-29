#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 rdball rdbsymfilt rdbcomplexfilt -csv ${KDBTESTS}/stp/subscription/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/subscription \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/subscription/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -runtime $1 \
  -procfile ${KDBTESTS}/stp/subscription/process.csv \
  -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stp1 rdball rdbsymfilt rdbcomplexfilt -csv ${KDBTESTS}/stp/subscription/process.csv
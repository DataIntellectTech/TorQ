#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 stp1 sctp1 rdball rdbsymfilt rdbcomplexfilt -csv ${KDBTESTS}/stp/chainedstp/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/chainedstp \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/chainedstp/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -runtime $1 \
  -procfile ${KDBTESTS}/stp/chainedstp/process.csv \
  -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stp1 sctp1 rdball rdbsymfilt rdbcomplexfilt -csv ${KDBTESTS}/stp/chainedstp/process.csv

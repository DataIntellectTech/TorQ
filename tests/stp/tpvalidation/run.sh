#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 tp1 rdball rdbsymfilt wdball wdbsymfilt wdbtabfilt -csv ${KDBTESTS}/stp/tpvalidation/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/tpvalidation -debug \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/tpvalidation/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -runtime $1 \
  -procfile ${KDBTESTS}/stp/tpvalidation/process.csv

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 tp1 rdball rdbsymfilt wdball wdbsymfilt wdbtabfilt -csv ${KDBTESTS}/stp/tpvalidation/process.csv

#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 rdball rdbsymfilt rdbonetab stp1 -csv ${KDBTESTS}/stp/periodend/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/periodend \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/periodend/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -procfile ${KDBTESTS}/stp/periodend/process.csv \
  -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 rdball rdbsymfilt rdbonetab stp1 -csv ${KDBTESTS}/stp/periodend/process.csv

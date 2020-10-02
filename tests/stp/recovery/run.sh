#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1 -csv ${KDBTESTS}/stp/recovery/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/recovery -debug \
  -load ${KDBTESTS}/helperfunctions.q ${KDBTESTS}/stp/recovery/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -runtime $1 \
  -procfile ${KDBTESTS}/stp/recovery/process.csv

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 rdball stprepperiod -csv ${KDBTESTS}/stp/recovery/process.csv
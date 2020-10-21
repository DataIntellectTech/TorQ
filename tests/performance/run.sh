#!/bin/bash

# Get localpath
localpath=$KDBTESTS/performance

# Start procs
${TORQHOME}/torq.sh start all -csv ${localpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype observer -procname observer1 \
  -load ${localpath}/observer.q ${localpath}/settings/observer.q \
  -procfile ${localpath}/process.csv \
  -noredirect

# Shut down procs
${TORQHOME}/torq.sh stop all -csv ${localpath}/process.csv
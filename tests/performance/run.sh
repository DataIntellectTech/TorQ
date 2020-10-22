#!/bin/bash

# Get localpath
localpath=$KDBTESTS/performance

# Start procs
${TORQHOME}/torq.sh start discovery1 feed1 stp1 consumer1 -csv ${localpath}/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype observer -procname observer1 \
  -load ${localpath}/settings/observer.q ${localpath}/observer.q \
  -procfile ${localpath}/process.csv \
  -noredirect

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 feed1 stp1 consumer1 -csv ${localpath}/process.csv
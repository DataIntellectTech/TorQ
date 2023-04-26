#!/bin/bash

# Get localpath
localpath=$KDBTESTS/performance

# Start procs
${TORQHOME}/torq.sh start discovery1 feed1 stp1 tp1 consumer1 tick1 -csv ${localpath}/settings/process.csv

# Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype observer -procname observer1 \
  -load ${localpath}/settings/observer.q ${localpath}/code/observer.q \
  -procfile ${localpath}/settings/process.csv \
  -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 feed1 stp1 tp1 consumer1 tick1 -csv ${localpath}/settings/process.csv

#!/bin/bash

# Parse command line arguments -s:stop mode, -q:quiet mode, -r:runtime
while getopts ":sqr:" opt; do
  case $opt in
    s ) stop="-stop" ;;
    q ) quiet="-q" ;;
    r ) run=$OPTARG ;;
    \?) echo "Usage: run.sh [-s] [-q] [-r runtimestamp]" && exit 1 ;;
    : ) echo "$OPTARG requires an argument" && exit 1 ;;
  esac
done

# Path to test directory
testpath=${KDBTESTS}/stp/subfile

${TORQHOME}/torq.sh start discovery1 stp1 rdb1 -csv ${testpath}/process.csv

/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -results ${KDBTESTS}/stp/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  -debug $stop $quiet

${TORQHOME}/torq.sh stop discovery1 stp1 rdb1 -csv ${testpath}/process.csv
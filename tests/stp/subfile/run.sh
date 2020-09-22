#!/bin/bash

${TORQHOME}/torq.sh start discovery1 stp1 rdb1 -csv ${KDBTESTS}/stp/subfile/process.csv
/usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype test -procname test1 \
  -test ${KDBTESTS}/stp/subfile/ -debug \
  -load ${KDBTESTS}/helperfunctions.q -csv ${KDBTESTS}/stp/subfile/process.csv
${TORQHOME}/torq.sh stop discovery1 stp1 rdb1 -csv ${KDBTESTS}/stp/subfile/process.csv
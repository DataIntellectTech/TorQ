#!/bin/bash

${TORQHOME}/torq.sh start discovery1 -csv ${KDBTESTS}/stp/recovery/process.csv
/usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype test -procname test1 -test ${KDBTESTS}/stp/recovery -debug
${TORQHOME}/torq.sh stop discovery1 -csv ${KDBTESTS}/stp/recovery/process.csv

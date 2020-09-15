#!/bin/bash

./torq.sh start discovery1 -csv ${KDBTESTS}/stp/recovery/process.csv
/usr/bin/rlwrap q torq.q -proctype test -procname test1 -test ${KDBTESTS}/stp/recovery -debug
./torq.sh stop discovery1 -csv ${KDBTESTS}/stp/recovery/process.csv

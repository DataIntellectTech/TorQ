#!/bin/bash

./torq.sh start discovery1 rdball rdbsymfilt rdbcomplexfilt -csv ${KDBTESTS}/stp/recovery/process.csv
/usr/bin/rlwrap q torq.q -proctype test -procname test1 -procfile ${KDBTESTS}/stp/recovery/process.csv -test ${KDBTESTS}/stp/recovery -debug
./torq.sh stop discovery1 rdball rdbsymfilt rdbcomplexfilt -csv ${KDBTESTS}/stp/recovery/process.csv

#!/bin/bash

./torq.sh start discovery1 -csv ${KDBTESTS}/stp/recovery/process.csv
./torq.sh start rdball -csv ${KDBTESTS}/stp/recovery/process.csv
./torq.sh start rdbsymfilt -csv ${KDBTESTS}/stp/recovery/process.csv
./torq.sh start rdbcomplexfilt -csv ${KDBTESTS}/stp/recovery/process.csv
/usr/bin/rlwrap q torq.q -proctype test -procname test1 -test ${KDBTESTS}/stp/recovery -debug -csv ${KDBTESTS}/stp/recovery/process.csv -procfile ${KDBTESTS}/stp/recovery/process.csv
./torq.sh stop all -csv ${KDBTESTS}/stp/recovery/process.csv

#!/bin/bash

testpath=${KDBTESTS}/rdb_QUnit

#${TORQHOME}/torq.sh start all -csv ${testpath}/processes.csv

${RLWRAP} ${QCMD} ${TORQHOME}/torqunit.q \
        -proctype test -procname test1 \
        -test ${testpath} -debug
       # -load ${testpath}/settings.q ${testpath}/rdbTest.q -debug
       # -procfile ${testpath}/processes.csv -debug

#${TORQHOME}/torq.sh stop all -csv ${testpath}/processes.csv

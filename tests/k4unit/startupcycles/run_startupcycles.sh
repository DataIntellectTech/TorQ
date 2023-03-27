#!/bin/bash

${TORQHOME}/torq.sh start discovery1
${TORQHOME}/torq.sh start stp1

#own
${QCMD} ${TORQHOME}/torq.q \
 -proctype rdb -procname rdb1 \
 -test ${KDBTESTS}/k4unit/startupcycles/ \
 -load ${KDBCODE}/processes/rdb.q  \
 -testresults ${KDBTESTS}/k4unit/logs/ \
 -runtime $run \
 $debug $stop $write $quiet

${TORQHOME}/torq.sh stop all

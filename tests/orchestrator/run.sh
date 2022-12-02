#!/bin/bash

#path to test directory
testpath=${KDBTESTS}/orchestrator

OLDKDBAPPCONFIG=${KDBAPPCONFIG}
export KDBAPPCONFIG=${testpath}

#start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/customprocess.csv

#Start test proc
/usr/bin/rlwrap $QCMD ${TORQHOME}/torq.q \
        -proctype orchestrator -procname orchestrator1 \
        -test ${testpath} \
        -load ${TORQHOME}/code/processes/orchestrator.q \
        -procfile ${testpath}/customprocess.csv -debug

#Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/customprocess.csv

export KDBAPPCONFIG=${OLDKDBAPPCONFIG}

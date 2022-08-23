#!/bin/bash

# path to test directory
testpath=$KDBTESTS/striping/stripednoid

# start procs
${TORQHOME}/torq.sh start discovery1 stp1 feed1 -csv ${testpath}/process.csv

# start test proc
$QCMD ${TORQHOME}/torq.q \
	-load ${KDBCODE}/processes/rdb.q \
	-proctype rdb -procname rdb1 \
	-test ${testpath} \
	-trap -debug

# shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv

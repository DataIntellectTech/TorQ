#!/bin/bash

# path to test directory
testpath=$KDBTESTS/striping/stripedvalidid
SETENV=$testpath/setconfig.sh

# start procs
${TORQHOME}/torq.sh start discovery1 stp1 feed1 -csv ${testpath}/appconfig/process.csv

# start test proc
$QCMD ${TORQHOME}/torq.q \
	-load ${KDBCODE}/processes/rdb.q \
	-proctype rdb -procname rdb1 \
	-test ${testpath} \
	-segid 1 \
	-trap -debug

# shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/appconfig/process.csv

#!/bin/bash

# path to test directory
testpath=$KDBTESTS/tailer/access
KDBTAIL=${testpath}/taildir

# start procs
${TORQHOME}/torq.sh start discovery1 stp1 rdb1 feed1 -csv ${testpath}/appconfig/process.csv

# start test proc
$QCMD ${TORQHOME}/torq.q \
	-load ${KDBCODE}/processes/wdb.q $KDBTESTS/helperfunctions.q ${testpath}/settings.q \
	-proctype wdb -procname wdb1 \
	-test ${testpath} \
	-.ds.datastripe 1 -segid 1 \
	-trap -debug

# shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/appconfig/process.csv

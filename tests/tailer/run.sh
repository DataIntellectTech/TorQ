#!/bin/bash

# path to test directory
export KDBAPPCONFIG=${TORQHOME}/tests/tailer/config

# start procs
${TORQHOME}/torq.sh start discovery1 stp1 feed1

# start test process
$QCMD ${TORQHOME}/torq.q \
	-load ${KDBCODE}/processes/rdb.q \
	-proctype rdb -procname rdb1 \
	-test ${TORQHOME}/tests/tailer -debug

# shut down procs
${TORQHOME}/torq.sh stop all -csv $TORQPROCESSES

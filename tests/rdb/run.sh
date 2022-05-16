#!/bin/bash

# Start procs
${TORQHOME}/torq.sh start discovery1
${TORQHOME}/torq.sh start stp1
${TORQHOME}/torq.sh start feed1

# Start test proc
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q -load ${KDBCODE}/processes/rdb.q -proctype rdb -procname rdb1 -test ${KDBTESTS}/rdb -debug

# Shut down procs
${TORQHOME}/torq.sh stop discovery1 stp1 feed1

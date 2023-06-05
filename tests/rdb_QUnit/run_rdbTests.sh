#!/bin/bash

#start the procs from bin directory- Depends on torq configuration: Wherever you start the stack
${TORQHOME}/../bin/torq.sh start discovery1 feed1 stp1 

# Path to test directory
testpath=${KDBTESTS}/rdb_QUnit

${RLWRAP} ${QCMD} ${TORQHOME}/torqunit.q \
        -proctype rdb -procname rdb1 \
        -test ${testpath} \
        -load ${KDBCODE}/processes/rdb.q -debug

#stop the procs
${TORQHOME}/../bin/torq.sh stop discovery1 feed1 stp1 

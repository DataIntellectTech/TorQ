#!/bin/bash

source $KDBTESTS/flagparse.sh

taskset -c 0,1 /usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype rdb -procname rdb1 -test ${KDBTESTS}/replication/rdbs -testresults ${KDBTESTS}/replication/rdbs/results -procfile ${KDBTESTS}/replication/rdbs/process.csv -segid 1 -debug $debug $stop $write $quiet

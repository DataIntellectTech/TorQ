#!/bin/bash

taskset -c 0,1 /usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype hdb -procname hdb1 -test ${KDBTESTS}/replication/hdbs -procfile ${KDBTESTS}/replication/hdbs/process.csv -segid 1 -debug

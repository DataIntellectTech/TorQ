#!/bin/bash

${TORQHOME}/torq.sh start discovery1 stp1 feed1
taskset -c 7,8 /usr/bin/rlwrap q ${TORQHOME}/torq.q -load ${KDBCODE}/processes/rdb.q -proctype rdb -procname rdb1 -test ${KDBTESTS}/striping/stripednoid -debug 
${TORQHOME}/torq.sh stop discovery1 stp1 feed1

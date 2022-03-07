#!/bin/bash

${TORQHOME}/torq.sh start discovery1 stp1 feed1
taskset -c 7,8 /usr/bin/rlwrap q ${TORQHOME}/torq.q -load ${KDBCODE}/processes/rdb.q -proctype rdb -procname rdb1 -segid 1 -extras ${KDBTESTS}/striping/stripedvalidid/segmenting.csv ${KDBTESTS}/striping/stripedvalidid/filtermap.csv -test ${KDBTESTS}/striping/stripedvalidid -debug 
${TORQHOME}/torq.sh stop discovery1 stp1 feed1

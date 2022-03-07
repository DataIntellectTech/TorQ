#!/bin/bash

${TORQHOME}/torq.sh start all

#start test process
taskset -c 0,1 /usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype segmentedtickerplant -procname stp1 -test ${TORQHOME}/tests/stp/configload/existTests -debug

${TORQHOME}/torq.sh stop all

#!/bin/bash

#path to segmenting.csv and filtermap.csv files
export KDBAPPCONFIG=${TORQHOME}/tests/stp/configload/matchTests/csvfiles

${TORQHOME}/torq.sh start all

#start test process
taskset -c 0,1 /usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype segmentedtickerplant -procname stp1 -test ${TORQHOME}/tests/stp/configload/matchTests -debug

${TORQHOME}/torq.sh stop all

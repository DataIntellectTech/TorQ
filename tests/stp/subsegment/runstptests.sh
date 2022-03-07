#!/bin/bash

./torq.sh start discovery1
./torq.sh start stp1
taskset -c 0,1 /usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype segmentedtickerplant -procname stp1 -test ./tests  -procfile ${KDBTESTS}/stp/subsegment/process.csv -schemafile ${TORQAPPHOME}/database.q -load ${KDBCODE}/processes/segmentedtickerplant.q -debug
./torq.sh stop all

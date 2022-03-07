#!/bin/bash

taskset -c 0,1 /usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype segmentedtickerplant -procname stp1 -test ${KDBTESTS}/stp/subsegment/  -procfile ${KDBTESTS}/stp/subsegment/process.csv -schemafile ${TORQAPPHOME}/database.q -load ${KDBCODE}/processes/segmentedtickerplant.q -debug


#!/bin/bash

nohup q ${KDBTESTS}/stp/subscription/dummyclient.q -schemafile ${TORQHOME}/database.q -p $((${KDBBASEPORT}+100)) &
/usr/bin/rlwrap q ${TORQHOME}/torq.q -load ${KDBCODE}/processes/segmentedtickerplant.q -schemafile ${TORQHOME}/database.q -proctype segmentedtickerplant -procname stp1 -test ${KDBTESTS}/stp/subscription -debug

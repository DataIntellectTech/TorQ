#!/bin/bash

nohup q ${KDBTESTS}/stp/dummyclient.q -schemafile ${TORQHOME}/database.q -p $((${KDBBASEPORT}+100)) &
/usr/bin/rlwrap q torq.q -load ${KDBCODE}/processes/segmentedtickerplant.q -schemafile ${TORQHOME}/database -stpconfig ${TORQHOME}/appconfig/settings/segmentedtickerplant.q -proctype segmentedtickerplant -procname stp1 -test ${KDBTESTS}/stp -debug

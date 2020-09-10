#!/bin/bash

./torq.sh start discovery1 -csv ${KDBTESTS}/stp/recovery/process.csv
./torq.sh start rdball -csv ${KDBTESTS}/stp/recovery/process.csv 
./torq.sh start rdbsymfilt -csv ${KDBTESTS}/stp/recovery/process.csv
./torq.sh start rdbcomplexfilt -csv ${KDBTESTS}/stp/recovery/process.csv
/usr/bin/rlwrap q torq.q -load ${KDBCODE}/processes/segmentedtickerplant.q -schemafile ${TORQHOME}/database.q -proctype segmentedtickerplant -procname stp1 -test ${KDBTESTS}/stp/recovery -debug -p $((${KDBBASEPORT}+104)) 
./torq.sh stop all -csv ${KDBTESTS}/stp/recovery/process.csv

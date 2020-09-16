#!/bin/bash

${TORQHOME}/torq.sh start discovery1 stp1 rdb1
/usr/bin/rlwrap q ${TORQHOME}/torq.q -proctype test -schemafile ${TORQHOME}/database.q -procname test1 -test ${KDBTESTS}/stp/batching/ -debug
${TORQHOME}/torq.sh stop discovery1 stp1 rdb1
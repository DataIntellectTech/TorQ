#!/bin/bash

#. ./setenv.sh
nohup q ${KDBTESTS}/stp/dummyclient.q -schemafile ${TORQHOME}/database.q -p $((${KDBBASEPORT}+100)) &
/usr/bin/rlwrap q torq.q -load ${KDBCODE}/processes/segmentedtp.q -schemafile ${TORQHOME}/database -stpconfig ${TORQHOME}/appconfig/settings/segmentedtp.q -proctype segmentedtp -procname stp1 -test ${KDBTESTS}/stp -debug

#!/bin/bash

source ${KDBTESTS}/flagparse.sh
#path to test directory
testpath=${KDBTESTS}/bglaunchprocess/

#start procs
${TORQHOME}/torq.sh start all -csv ${testpath}/process.csv

#Start test proc
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
	-proctype test -procname test1 \
	-test ${testpath} \
	-load ${TORQHOME}/code/common/bglaunchutils.q ${testpath}/settings.q     \
	-procfile ${testpath}/process.csv $debug
# get the return code from the tests
RC=$?

#Shut down procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/process.csv

if [ $RC -ne 0 ]; then 
    STATUS="FAILED"
else 
    STATUS="PASSED"
fi
echo "Bglaunchprocess Tests complete - status = $STATUS"
exit $RC

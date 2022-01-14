#!/bin/bash
cd $HOME/TorQ/deploy/TorQ/latest
source setenv.sh

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Different process configs
for stripe in nostripe partialstripe fullstripe
do
	# Path to test directory
	testpath=${KDBTESTS}/dataaccess/gatewayroutingstripe

	# Start procs
	${TORQHOME}/torq.sh start all -csv ${testpath}/${stripe}/process.csv
	
	# Start test proc
	QCMD='taskset -c 0,1 /usr/bin/rlwrap q'
	${QCMD} ${TORQHOME}/torq.q \
		-proctype test -procname test${stripe} \
		-test ${testpath} \
		-load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
		-testresults ${testpath}/results/${stripe} \
		-runtime $run \
		-procfile ${testpath}/${stripe}/process.csv \
		$debug $stop $write $quiet

    # Stop procs to change .ds.numseg and .rdb.subfiltered
    ${TORQHOME}/torq.sh stop stp1 rdb1 rdb2 rdb3 rdb4 gateway1 -csv ${testpath}/${stripe}/process.csv
done

# Stop procs
${TORQHOME}/torq.sh stop all -csv ${testpath}/${stripe}/process.csv

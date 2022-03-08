#!/bin/bash

#start test process
$QCMD ${TORQHOME}/torq.q \
	-proctype segmentedtickerplant \
	-procname stp1 \
	-test ${TORQHOME}/tests/stp/configload/existTests \
	-debug

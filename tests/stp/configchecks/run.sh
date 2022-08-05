#!/bin/bash

source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/stp/configchecks

# Start test proc
$QCMD ${TORQHOME}/torq.q \
  -load ${KDBCODE}/processes/segmentedtickerplant.q \
  -proctype segmentedtickerplant -procname stp1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q \
  -schemafile ${TORQAPPHOME}/database.q \
  -runtime $run \
  -testresults ${testpath}/results \
  $debug $stop $write $quiet

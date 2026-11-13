#!/bin/bash
# Engine compatibility tests: engine detection, .proc.capabilities and every place TorQ reads it.
# Runs on whichever engine "q" on the PATH is. Set TORQTEST_ENGINE (kdb, l or peachq) to also check the detection.

source $KDBTESTS/flagparse.sh

testpath=${KDBTESTS}/engine
port=$((KDBBASEPORT+120))

# plain q server (not TorQ) on the same engine, for the IPC checks
q ${testpath}/server.q -p $port -q </dev/null >/dev/null 2>&1 &
serverpid=$!
sleep 2

q ${TORQHOME}/torq.q \
  -proctype test -procname test1 \
  -test ${testpath} \
  -load ${KDBTESTS}/helperfunctions.q ${testpath}/settings.q \
  -testresults ${KDBTESTS}/engine/results/ \
  -procfile ${testpath}/process.csv \
  -runtime $run \
  $debug $stop $write $quiet

kill $serverpid 2>/dev/null

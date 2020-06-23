#!/bin/bash

./torq.sh start discovery1
./torq.sh start stp1
./torq.sh start feed1
/usr/bin/rlwrap q torq.q -load ${KDBCODE}/processes/rdb.q -proctype rdb -procname rdb1 -test ${KDBTESTS}/rdb -debug
./torq.sh stop all

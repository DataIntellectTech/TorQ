#!/bin/bash

./torq.sh start discovery1
./torq.sh start tickerplant1
./torq.sh start stp1
./torq.sh start rdb1
/usr/bin/rlwrap q torq.q -proctype test -procname test1 -test ${KDBTESTS}/stp/subfile/ -debug
./torq.sh stop all
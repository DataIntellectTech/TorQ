#!/bin/bash

./torq.sh start discovery1 tickerplant1 stp1 rdb1
/usr/bin/rlwrap q torq.q -proctype test -procname test1 -test ${KDBTESTS}/stp/subfile/ -debug
./torq.sh stop discovery1 tickerplant1 stp1 rdb1
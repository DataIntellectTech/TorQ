#!/bin/bash
# This script runs tests 

# 3.1.1 Log Replay all tables

# Old tp log format
q torq.q -load $KDBCODE/processes/tickerlogreplay.q -.replay.tplogfile $KDBTESTS/stp/tickerlog/testlogs/database2020.09.20 -proctype tickerlogreplay -procname tickerlogreplay1 -procfile ${KDBAPPCONFIG}/process.csv -localtime -.replay.schemafile database.q -.replay.hdbdir $KDBTESTS/stp/tickerlog/testhdb/ -.replay.segmentedmode 0 -.replay.exitwhencomplete 0 -test $KDBTESTS/stp/tickerlog/

# Clean up hdb dir and end process

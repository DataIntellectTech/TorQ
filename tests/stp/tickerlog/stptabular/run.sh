#!/bin/bash
# This script runs tests 

q $TORQHOME/torq.q \
	-load $KDBCODE/processes/tickerlogreplay.q $KDBTESTS/stp/tickerlog/settings.q \
	-.replay.tplogfile $KDBTESTS/stp/tickerlog/stptabular/testlogs/stptabular \
	-proctype tickerlogreplay -procname tickerlogreplay1 \
	-procfile $KDBAPPCONFIG/process.csv \
	-localtime \
	-.replay.schemafile $TORQHOME/database.q \
	-.replay.hdbdir $KDBTESTS/stp/tickerlog/stptabular/testhdb/ \
	-.replay.exitwhencomplete 0 \
	-.replay.segmentedmode 1 \
	-test $KDBTESTS/stp/tickerlog/stptabular/ \
	-debug


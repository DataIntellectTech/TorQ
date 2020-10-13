#!/bin/bash
# This script runs tests 

q $TORQHOME/torq.q \
	-load $KDBCODE/processes/tickerlogreplay.q $KDBTESTS/stp/tickerlog/settings.q \
	-.replay.tplogfile $KDBTESTS/stp/tickerlog/stptabperiod/testlogs/stptabperiod \
	-proctype tickerlogreplay -procname tickerlogreplay1 \
	-procfile $KDBAPPCONFIG/process.csv \
	-localtime \
	-.replay.schemafile $TORQHOME/database.q \
	-.replay.hdbdir $KDBTESTS/stp/tickerlog/stptabperiod/testhdb/ \
	-.replay.exitwhencomplete 0 \
	-.replay.segmentedmode 1 \
	-test $KDBTESTS/stp/tickerlog/stptabperiod/ \
	-debug


#!/bin/bash
# This script runs tests 

q torq.q \
	-load $KDBCODE/processes/tickerlogreplay.q $KDBTESTS/stp/tickerlog/settings.q \
	-.replay.tplogfile $KDBTESTS/stp/tickerlog/testlogs/testoldlog \
	-proctype tickerlogreplay -procname tickerlogreplay1 \
	-procfile ${KDBAPPCONFIG}/process.csv \
	-localtime \
	-.replay.schemafile database.q \
	-.replay.hdbdir $KDBTESTS/stp/tickerlog/testhdb/ \
	-.replay.exitwhencomplete 0 \
	-.replay.segmentedmode 0 \
	-test $KDBTESTS/stp/tickerlog/ \
	-debug


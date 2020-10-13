#!/bin/bash
# This script runs tickerlog replay tests 

# STP none
q $TORQHOME/torq.q \
	-load $KDBCODE/processes/tickerlogreplay.q $KDBTESTS/stp/tickerlog/settings.q \
	-.replay.tplogfile $KDBTESTS/stp/tickerlog/stpnone/testlogs/stpnone/ \
	-proctype tickerlogreplay -procname tickerlogreplay1 \
	-procfile $KDBAPPCONFIG/process.csv \
	-localtime \
	-.replay.schemafile $TORQHOME/database.q \
	-.replay.hdbdir $KDBTESTS/stp/tickerlog/stpnone/testhdb/ \
	-.replay.exitwhencomplete 0 \
	-.replay.segmentedmode 1 \
	-test $KDBTESTS/stp/tickerlog/stpnone/ \
	-debug


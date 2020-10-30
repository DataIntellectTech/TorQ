# housekeeping
cp -r $KDBTESTS/stp/housekeeping/testlog/teststpnone $KDBTESTS/stp/housekeeping/testlog/testlog

q $TORQHOME/torq.q \
        -load $KDBCODE/processes/housekeeping.q $KDBTESTS/stp/housekeeping/settings.q \
        -proctype tickerlogreplay -procname tickerlogreplay1 \
        -procfile $KDBAPPCONFIG/process.csv \
        -localtime \
        -test $KDBTESTS/stp/housekeeping/ \
        -debug

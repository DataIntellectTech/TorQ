#!/bin/bash

. ${KDBTESTS}/flagparse.sh

ALREADYPROCESSED=${KDBTESTS}/pcap/settings/filealerterprocessed

${TORQHOME}/torq.sh start discovery1 -csv ${KDBTESTS}/pcap/settings/process.csv
${TORQHOME}/torq.sh start tickerplant1 -csv ${KDBTESTS}/pcap/settings/process.csv
${TORQHOME}/torq.sh start rdb1 -csv ${KDBTESTS}/pcap/settings/process.csv -extras -.rdb.replaylog 0
${RLWRAP} ${QCMD} ${TORQHOME}/torq.q -load ${KDBCODE}/processes/filealerter.q \
    -proctype filealerter -procname filealerter1 \
    -procfile ${KDBTESTS}/pcap/settings/process.csv \
    -test ${KDBTESTS}/pcap ${debug} \
    -.fa.polltime 00:10  \
    -.fa.inputcsv ${KDBTESTS}/pcap/settings/dummyfilealerter.csv \
    -.fa.alreadyprocessed ${ALREADYPROCESSED} \
    -.fa.tickerplanttypes tickerplant

RC=$?
${TORQHOME}/torq.sh stop all -csv ${KDBTESTS}/pcap/settings/process.csv
rm -rf ${ALREADYPROCESSED}

exit $RC
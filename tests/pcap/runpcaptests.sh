#!/bin/bash

./torq.sh start discovery1
./torq.sh start tickerplant1 -extras -tplogdir ${KDBTESTS}/pcap
./torq.sh start rdb1 -extras -.rdb.replaylog 0
/usr/bin/rlwrap q torq.q -load ${KDBCODE}/processes/filealerter.q -proctype filealerter -procname filealerter1 -test ${KDBTESTS}/pcap -debug -.fa.decodepcaps 1 -.fa.polltime 00:10 -.servers.CONNECTIONS rdb -.fa.alreadyprocessed ${KDBTESTS}/pcap/filealerterprocessed -.fa.inputcsv ${KDBTESTS}/pcap/filealerter.csv
./torq.sh stop all

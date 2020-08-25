#!/bin/bash

./torq.sh start discovery1
./torq.sh start tickerplant1 
./torq.sh start rdb1 -extras -.rdb.replaylog 0
rlwrap q torq.q -load ${KDBCODE}/processes/filealerter.q -proctype filealerter -procname filealerter1 -test ${KDBTESTS}/pcap -debug -.fa.polltime 00:10 -.servers.CONNECTIONS -.fa.tickerplanttype -.fa.alreadyprocessed ${KDBTESTS}/pcap/filealerterprocessed -.fa.inputcsv ${KDBTESTS}/pcap/dummyfilealerter.csv
./torq.sh stop all

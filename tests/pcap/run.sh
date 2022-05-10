#!/bin/bash

# Handle command-line arguments
source $KDBTESTS/flagparse.sh

# Path to test directory
testpath=${KDBTESTS}/pcap

#start processes for stp pcap tests
${TORQHOME}/torq.sh start discovery1 stp1 rdb1 -csv ${testpath}/process.csv

#start test process
/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -load ${KDBCODE}/processes/filealerter.q ${KDBTESTS}/helperfunctions.q \
  -proctype filealerter -procname filealerter1 \
  -test ${KDBTESTS}/pcap \
  -.fa.polltime 00:10 -.servers.CONNECTIONS -.fa.tickerplanttype -.fa.alreadyprocessed ${KDBTESTS}/pcap/filealerterprocessed -.fa.inputcsv ${KDBTESTS}/pcap/dummyfilealerter.csv \
  -testresults ${KDBTESTS}/pcap/results/ \
  $quiet $write $debug

#stp test procs are stopped in pcapdecoder.csv

#start processes with tickerplant to test pcap on tickerplant
${TORQHOME}/torq.sh start discovery1 tickerplant1 rdb1 -csv ${testpath}/process.csv

/usr/bin/rlwrap q ${TORQHOME}/torq.q \
  -load ${KDBCODE}/processes/filealerter.q ${KDBTESTS}/helperfunctions.q \
  -proctype filealerter -procname filealerter2 \
  -test ${KDBTESTS}/pcap/oldtptests \
  -.fa.polltime 00:10 -.servers.CONNECTIONS -.fa.tickerplanttype -.fa.alreadyprocessed ${KDBTESTS}/pcap/filealerterprocessed -.fa.inputcsv ${KDBTESTS}/pcap/dummyfilealerter.csv \
  -testresults ${KDBTESTS}/pcap/oldtptests/results/ \
  $quiet $write $debug

#stop processes for tickerplant tests
${TORQHOME}/torq.sh stop discovery1 tickerplant1 rdb1 -csv ${testpath}/process.csv

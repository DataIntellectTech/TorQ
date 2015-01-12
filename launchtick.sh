# Load the environment
. ./setenv.sh

# launch the tickerplant, rdb, hdb
q tickerplant.q exampleschema hdb -p 5010 </dev/null >$KDBLOG/torqtp.txt 2>&1 &
q torq.q :5010 :5012 -load tick/r.q -p 5011 </dev/null >$KDBLOG/torqrdb.txt 2>&1 &
q torq.q -load hdb/exampleschema -p 5012 </dev/null >$KDBLOG/torqhdb.txt 2>&1 &

# launch the discovery service
q torq.q -load code/processes/discovery.q -p 9995 </dev/null >$KDBLOG/torqdiscovery.txt 2>&1 &

# launch the gateway
q torq.q -load code/processes/gateway.q -p 5020 -.servers.CONNECTIONS hdb rdb </dev/null >$KDBLOG/torqgw.txt 2>&1 &

# launch the monitor
q torq.q -load code/processes/monitor.q -p 20001 </dev/null >$KDBLOG/torqmonitor.txt 2>&1 &

# launch housekeeping
q torq.q -load code/processes/housekeeping.q -p 20003 </dev/null >$KDBLOG/torqhousekeeping.txt 2>&1 &

# to kill it, run this:
#q torq.q -load code/processes/kill.q -p 20000 -.servers.CONNECTIONS rdb tickerplant hdb gateway housekeeping monitor discovery </dev/null >$KDBLOG/torqkill.txt 2>&1 &

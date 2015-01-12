REM see README.txt
REM SET UP ENVIRONMENT VARIABLES 

set KDBCODE=C:/q/code
set KDBCONFIG=C:/q/config
set KDBLOG=C:/q/logs
set KDBHTML=C:/q/html

REM launch the tickerplant, rdb, hdb
start "tickerplant" q tickerplant.q exampleschema hdb -p 5010
start "rdb" q torq.q :5010 :5012 -load tick/r.q -p 5011 
start "hdb" q torq.q -load hdb/exampleschema -p 5012

REM launch the discovery service
start "discovery" q torq.q -load code/processes/discovery.q -p 9995 

REM launch the gateway
start "gateway" q torq.q -load code/processes/gateway.q -p 5020 -.servers.CONNECTIONS hdb rdb 

REM launch the monitor
start "monitor" q torq.q -load code/processes/monitor.q -p 20001 

REM launch housekeeping
start "housekeeing" q torq.q -load code/processes/housekeeping.q -p 20003

REM to kill it, run this:
REM q torq.q -load code/processes/kill.q -p 20000 -.servers.CONNECTIONS rdb tickerplant hdb gateway housekeeping monitor discovery

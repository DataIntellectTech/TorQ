/ Chained Tickerplant

\d .ctp
tickerplantname:`tickerplant1;	/- list of tickerplant types to try and make a connection to
pubinterval:0D00:00:00;       	/- publish batch updates at this interval, 0D00:00:00 for tick by tick
tpconnsleep:10;			/- number of seconds between attempts to connect to the source tickerplant   
createlogfile:0b;             	/- create a log file
logdir:`:tplogs;		/- hdb directory containing tp logs
subscribeto:`;                	/- list of tables to subscribe for
subscribesyms:`;              	/- list of syms to subscription to
replay:0b;                    	/- replay the tickerplant log file
schema:1b;                    	/- retrieve schema from tickerplant
clearlogonsubscription:0b;	/- clear logfile on subscription

\d .servers
CONNECTIONS:`tickerplant 	/- list of connections to make at start up
STARTUP:1b                    	/- create connections

\d .hb
enabled:0b                    	/- disable heartbeating

/- Configuration used by the usage functions - logging of client interaction
\d .usage
enabled:0b                    	/- switch off the usage logging

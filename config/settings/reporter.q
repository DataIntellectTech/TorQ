/- Reporter config

\d .rp

inputcsv:first .proc.getconfigfile["reporter.csv"];	/- Location of report configuration csv file
flushqueryloginterval:1D00:00:00;		/- How often to flush the report query log data
writetostdout:1b;			  	/- whether to write query log info to standard out as well	

\d .servers
CONNECTIONS:`gateway`rdb`hdb				/- create connections to all processes

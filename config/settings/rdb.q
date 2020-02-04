// Bespoke RDB config

\d .rdb
ignorelist:`heartbeat`logmsg	//list of tables to ignore when saving to disk
hdbtypes:`hdb    		//list of hdb types to look for and call in hdb reload
hdbnames:()			//list of hdb names to search for and call in hdb reload
tickerplanttypes:`tickerplant	//list of tickerplant types to try and make a connection to
gatewaytypes:`gateway		//list of gateway types to try and make a connection to
checktpperiod:0D00:00:05	//how often to check for tickerplant connection
onlyclearsaved:0b		//if true, eod writedown will only clear tables which have been successfully saved to disk
subscribeto:`			//a list of tables to subscribe to, default (`) means all tables
subscribesyms:`			//a list of syms to subscribe for, (`) means all syms
savetables:1b			//if true tables will be saved at end of day, if false tables wil not be saved, only wiped
garbagecollect:1b		//if true .Q.gc will be called after each writedown - tradeoff: latency vs memory usage
upd:insert			//value of upd
hdbdir:`:hdb			//the location of the hdb directory
replaylog:1b			//replay the tickerplant log file
schema:1b			//retrieve the schema from the tickerplant
tpconnsleepintv:10		//number of seconds between attempts to connect to the tp                                                                 
gc:1b				//if true .Q.gc will be called after each writedown - tradeoff: latency vs memory usage
sortcsv:hsym first .proc.getconfigfile["sort.csv"]	//location of csv file
reloadenabled:0b		//if true, the RDB will not save when .u.end is called but
               			//will clear it's data using reload function (called by the WDB)
parvaluesrc:`log		//where to source the rdb partition value, can be log (from tp log file name),
				//tab (from the the first value in the time column of the table that is subscribed for)
				//anything else will return a null date which is will be filled by pardefault                                             
pardefault:.z.D			//if the src defined in parvaluesrc returns null, use this default date instead
tpcheckcycles:0W                //specify the number of times the process will check for an available tickerplant

\d .proc
loadprocesscode:1b              // whether to load the process specific code defined at ${KDBCODE}/{process type}

// Server connection details
\d .servers
CONNECTIONS:`hdb		// list of connections to make at start up
STARTUP:1b			// create connections


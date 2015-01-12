// Default configuration - loaded by all processes

// Process initialisation
\d .proc
loadcommoncode:1b		// whether to load the common code defined at ${KDBCODE}/common
loadprocesscode:0b		// whether to load the process specific code defined at ${KDBCODE}/{process type} 
loadnamecode:0b			// whether to load the name specific code defined at ${KDBCODE}/{name of process}
loadhandlers:1b			// whether to load the message handler code defined at ${KDBCODE}/handlers
logroll:1b			// whether to roll the std out/err logs on a daily basis

// logging config
\d .lg
outmap:`ERR`INF`WARN!2 1 1	// where each log level is output (0=none; 1=std out; 2=std err)

// Configuration used by the usage functions - logging of client interaction
\d .usage
enabled:1b			// whether the usage logging is enabled
logtodisk:1b                    // whether to log to disk or not
logtomemory:1b                  // write query logs to memory
ignore:1b			// check the ignore list for functions to ignore
ignorelist:(`upd;"upd")		// the list of functions to ignore in async calls
flushtime:1D00                  // default value for how long to persist the in-memory logs. Set to 0D for no flushing
suppressalias:0b                // whether to suppress the log file alias creation
logtimestamp:{[].z.d}      	// function to generate the log file timestamp suffix
LEVEL:3				// log level. 0=none;1=errors;2=errors+complete queries;3=errors+before a query+after
logroll:1b			// Whether or not to roll the log file automatically (on a daily schedule)

// Client tracking configuration
\d .clients
enabled:1b			// whether client tracking is enabled
opencloseonly:0b	        // whether we only log opening and closing of connections
INTRUSIVE:0b			// interrogate clients for more information upon connection.  Do not use if there are any non-kdb+ clients
AUTOCLEAN:1b			// clean out old records when handling a close
RETAIN:`long$0D02		// length of time to retain client information 
MAXIDLE:`long$0D		// handles which haven't been used in this length of time will be closed. 0 means no clean up

// Access controls
\d .access
enabled:0b			// whether the access controls are enabled
openonly:0b		        // only check permissions when the connection is made, not on every call
MAXSIZE:2000000000		// the maximimum size in bytes for any result set

// Server connection details
\d .servers
enabled:1b											// whether server tracking is enabled
CONNECTIONS:`rdb`hdb										// list of connections to make at start up
DISCOVERYREGISTER:1b										// whether to register with the discovery service
CONNECTIONSFROMDISCOVERY:1b									// whether to get connection details from the discovery service (as opposed to the static file).
TRACKNONTORQPROCESS:1b          								// whether to track and register non torQ processes 
NONTORQPROCESSFILE:hsym`$getenv[`KDBCONFIG],"/nontorqprocess.csv"   				// non torQ processes file
SUBSCRIBETODISCOVERY:1b										// whether to subscribe to the discovery service for new processes becoming available
DISCOVERYRETRY:0D00:05										// how often to retry the connection to the discovery service.  If 0, no connection is made. This also dictates if the discovery service can connect it and cause it to re-register itself (val > 0)
HOPENTIMEOUT:2000 										// new connection time out value in milliseconds
RETRY:0D00:05											// period on which to retry dead connections.  If 0, no reconnection attempts
RETAIN:`long$0D00:30 										// length of time to retain server records
AUTOCLEAN:1b											// clean out old records when handling a close
DEBUG:1b											// log messages when opening new connections
LOADPASSWORD:1b											// load the external username:password from ${KDBCONFIG}/passwords
STARTUP:0b    											// whether to automatically make connections on startup
DISCOVERY:enlist`										// list of discovery services to connect to (if not using process.csv)

// functions to ignore when called async - bypass all permission checking and logging
\d .zpsignore
enabled:1b					// whether its enabled 
ignorelist:(`upd;"upd";`.u.upd;".u.upd")	// list of functions to ignore

// timer functions
\d .timer 
enabled:1b			// whether the timer is enabled
debug:0b                    	// print when the timer runs any function
logcall:1b                  	// log each timer call by passing it through the 0 handle
nextscheduledefault:2h		// the default way to schedule the next timer
                               	// Assume there is a function f which should run at time T0, actually runs at time T1, and finishes at time T2
                        	// if mode 0, nextrun is scheduled for T0+period
                           	// if mode 1, nextrun is scheduled for T1+period
                              	// if mode 2, nextrun is scheduled for T2+period

// caching functions
\d .cache
maxsize:500			// the maximum size in MB of the cache as a whole. Evaluated using -22!. To be sure, set to half the required size
maxindividual:100		// the maximum size in MB of any individual item in the cache. Evaluated using -22!. To be sure, set to half the required size

// timezone functions
\d .tz
default:`$"Europe/London"	// default local timezone

// heartbeating
\d .hb
enabled:1b			// whether the heartbeating is enabled
debug:1b			// whether to print debug information
publishinterval:0D00:00:30	// how often heartbeats are published
checkinterval:0D00:00:10	// how often heartbeats are checked
warningtolerance:2f		// a process will move to warning state when it hasn't heartbeated in warningtolerance*checkinterval
errortolerance:3f		// and to an error state when it hasn't heartbeated in errortolerance*checkinterval

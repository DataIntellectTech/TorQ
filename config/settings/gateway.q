// Default configuration for the gateway process

\d .gw
synccallsallowed:0b		// whether synchronous calls are allowed
querykeeptime:0D00:30		// the time to keep queries in the
errorprefix:"error: "		// the prefix for clients to look for in error strings

// Server connection details
\d .servers
CONNECTIONS:`rdb`hdb		// list of connections to make at start up
RETRY:0D00:01                   // period on which to retry dead connections.  If 0, no reconnection attempts

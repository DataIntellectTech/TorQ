// Default configuration for the gateway process

\d .gw
// if error & sync message, throws an error. Else passes result as normal
// status - 1b=success, 0b=error. sync - 1b=sync, 0b=async
formatresponse:{[status;sync;result]$[not[status]and sync;'result;result]};
synccallsallowed:0b		// whether synchronous calls are allowed
querykeeptime:0D00:30		// the time to keep queries in the
errorprefix:"error: "		// the prefix for clients to look for in error strings
clearinactivetime:0D01:00	// the time to keep inactive handle data

\d .proc
loadprocesscode:1b              // whether to load the process specific code defined at ${KDBCODE}/{process type}

// Server connection details
\d .servers
CONNECTIONS:`rdb`hdb		// list of connections to make at start up
RETRY:0D00:01                   // period on which to retry dead connections.  If 0, no reconnection attempts

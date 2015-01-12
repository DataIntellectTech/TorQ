// Default configuration - loaded by all processes

// Server connection details
\d .servers
enabled:1b					// whether server tracking is enabled
CONNECTIONS:`hdb`rdb`tickerplant`gateway	// list of connections to make at start up
DISCOVERYREGISTER:0b				// whether to register with the discovery service
CONNECTIONSFROMDISCOVERY:1b			// whether to get connection details from the discovery service (as opposed to the static file)
SUBSCRIBETODISCOVERY:0b				// whether to subscribe to the discovery service for new processes becoming available
DISCOVERYRETRY:0D00:05				// how often to retry the connection to the discovery service.  If 0, no connection is made. This also dictates if the discovery service can connect it and cause it to re-register itself (val > 0)
HOPENTIMEOUT:2000	 			// new connection time out value in milliseconds
RETRY:0D00:05					// length of time to retry dead connections.  If 0, no reconnection attempts
RETAIN:`long$0D00:30 				// length of time to retain server records
AUTOCLEAN:1b					// clean out old records when handling a close
DEBUG:1b					// log messages when opening new connections

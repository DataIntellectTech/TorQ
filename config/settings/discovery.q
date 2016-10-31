// Bespoke config for the discovery service

// Server connection details
\d .servers
CONNECTIONS:`ALL		// list of connections to make at start up
DISCOVERYREGISTER:0b		// whether to register with the discovery service
CONNECTIONSFROMDISCOVERY:0b	// whether to get connection details from the discovery service (as opposed to the static file)
TRACKNONTORQPROCESS:1b 		// whether to track and register non torQ processes throught discovery. 
DISCOVERYRETRY:0D		// how often to retry the connection to the discovery service.  If 0, no connection is made
HOPENTIMEOUT:200 		// new connection time out value in milliseconds
RETRY:0D00			// length of time to retry dead connections.  If 0, no reconnection attempts
RETAIN:`long$0Wp 		// length of time to retain server records
AUTOCLEAN:0b			// clean out old records when handling a close
DEBUG:1b			// log messages when opening new connections

//==========================================================================================

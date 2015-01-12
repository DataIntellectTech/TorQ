// tickerplant configuration

// Process initialisation
\d .proc
loadcommoncode:0b		// do not load common code
loadprocesscode:0b		// do not load process code
loadnamecode:0b			// do not load name code
loadhandlers:1b			// load the message handles (but switch most off)
logroll:0b			// do not roll logs

// Configuration used by the usage functions - logging of client interaction
\d .usage
enabled:0b			// switch off the usage logging

// Client tracking configuration
// This is the only thing we want to do
// and only for connections being opened and closed
\d .clients
enabled:1b			// whether client tracking is enabled
opencloseonly:1b		// only log open and closing of connections
INTRUSIVE:0b			// do not interrogate clients
AUTOCLEAN:1b			// clean out old records when handling a close
RETAIN:`long$0D02		// length of time to retain client information 
MAXIDLE:`long$0D		// no closing of idle connections

// Access controls
\d .access
enabled:0b			// disable access controls

// Server connection details
\d .servers
enabled:0b			// disable server tracking

\d .timer
enabled:0b 			// disable the timer

\d .hb
enabled:0b			// disable heartbeating

\d .zpsignore
enabled:0b			// disable zpsignore - zps should be empty  

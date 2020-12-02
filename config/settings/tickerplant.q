// Tickerplant config

\d .proc
loadcommoncode:0b		// do not load common code

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

// Server connection details
\d .servers
enabled:0b			// disable server tracking

\d .timer
enabled:0b 			// disable the timer

\d .hb
enabled:0b			// disable heartbeating

\d .zpsignore
enabled:0b			// disable zpsignore - zps should be empty  


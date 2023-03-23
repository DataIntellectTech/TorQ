// Bespoke HDB config

\d .proc
loadprocesscode:1b              // whether to load the process specific code defined at ${KDBCODE}/{process type}

// Server connection details
\d .servers
CONNECTIONS:()			// list of connections to make at start up
STARTUP:1b                      // create connections

\d .hdb
expectedreloadcalls:1    // the number of reload calls that need to be received before acting -
                         // it could be the same as the number of the WDB processes, the number of the
                         // RDB processes, or the sum of both


// Bespoke HDB config
\d .hdb
ignorelist:`packets             // list of tables to ignore retrieving attributes from to send to gateways

\d .proc
loadprocesscode:1b              // whether to load the process specific code defined at ${KDBCODE}/{process type}

// Server connection details
\d .servers
CONNECTIONS:`gateway			// list of connections to make at start up
STARTUP:1b                      // create connections


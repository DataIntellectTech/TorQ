// Bespoke HDB config

\d .proc
loadprocesscode:1b              // whether to load the process specific code defined at ${KDBCODE}/{process type}

// Server connection details
\d .servers
CONNECTIONS:()			// list of connections to make at start up
STARTUP:1b                      // create connections


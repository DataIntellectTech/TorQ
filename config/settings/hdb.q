// Bespoke HDB config

\d .proc
loadprocesscode:1b              // whether to load the process specific code defined at ${KDBCODE}/{process type}

// Server connection details
\d .servers
CONNECTIONS:`hdb		// list of connections to make at start up
STARTUP:1b                      // create connections

// Access controls
\d .access
enabled:0b                      // disable access controls
                                // it is tricky to make access controls work without 
                                // customising kdb+tick itself
                                // due to the way it opens connections and sends messages
                                // e.g. the end-of-day reload

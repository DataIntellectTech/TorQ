// Bespoke IDB config

// Server connection details
\d .servers
CONNECTIONS:()                                                                              // list of connections to make at start up
STARTUP:1b                                                                                  // create connections

\d .proc
loadprocesscode:1b                                                                          // whether to load the process specific code defined at ${KDBCODE}/{process type}

\d .idb
savedir:hsym`$getenv[`KDBWDB]                                                               // location of the wdb data
hdbdir:hsym`$getenv[`KDBHDB]                                                                // location of the hdb data

// Bespoke IDB config

// Server connection details
\d .servers
CONNECTIONS:`wdb                                                                            // list of connections to make at start up
STARTUP:1b                                                                                  // create connections

\d .proc
loadprocesscode:0b                                                                          // whether to load the process specific code defined at ${KDBCODE}/{process type}

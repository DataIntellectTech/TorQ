\d .proc
loadprocesscode:1b       // whether to load the process specific code defined at ${KDBCODE}/{process type}

\d .servers
/centraltailsorttypes:`centraltailsort
CONNECTIONS:`rdb_seg1`rdb_seg2`centraltailsort  // connections to make at start up
STARTUP:1b                                      // create connections

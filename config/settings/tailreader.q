\d .wdb
ignorelist:`heartbeat`logmsg    /list of tables to ignore when performing operations e.g. attribute retrieval for query routing

\d .servers
CONNECTIONS:`gateway        /list connections to be made at startup
STARTUP:1b                  /create connections

\d .proc
loadprocesscode:1b  // whether to load the process specific code defined at ${KDBCODE}/{process type}
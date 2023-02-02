\d .proc
loadprocesscode:1b       // whether to load the process specific code defined at ${KDBCODE}/{process type}

\d .servers
CONNECTIONS:`rdb`centraltailsort // connections to make at start up
STARTUP:1b                       // create connections

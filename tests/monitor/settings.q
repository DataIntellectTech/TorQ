// IPC connection parameters
.servers.CONNECTIONS:`monitor;
.servers.USERPASS:`admin:admin;

// the monitor's web page calls start on every connection, which subscribes these with .html.wssub
// (heartbeat and logmsg are tables, lmchart is a function)
monsubs:`heartbeat`logmsg`lmchart;

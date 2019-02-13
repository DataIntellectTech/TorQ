// Default configuration for the monitor process
.monit.configcsv: first .proc.getconfigfile["monitorconfig.csv"];
.monit.configstored:first .proc.getconfigfile["monitorconfig"];
.monit.checkinterval:0D00:00:05;
.monit.checktimeinterval:0D00:00:07;

// Server connection details
\d .servers
CONNECTIONS:`ALL		// list of connections to make at start up

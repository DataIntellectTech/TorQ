// Default configuration for the monitor process
.monit.configcsv: first .proc.getconfigfile["monitorconfig.csv"];
.monit.configstored:first .proc.getconfigfile["monitorconfig"];

// Server connection details
\d .servers
CONNECTIONS:`ALL		// list of connections to make at start up

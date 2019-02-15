// Default configuration for the monitor process

\d .monitor 
configcsv: first .proc.getconfigfile["monitorconfig.csv"];
configstored:first .proc.getconfigfile["monitorconfig"];
checkinterval:0D00:00:05;
checktimeinterval:0D00:00:07;

//Enable loading
\d .proc
loadprocesscode:1b              //whether to load process specific code defined at ${KDBCODE}/{process type} 

// Server connection details
\d .servers
CONNECTIONS:`ALL		// list of connections to make at start up

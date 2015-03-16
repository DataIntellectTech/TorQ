/- Default configuration file for the compression process

/- switch off some of the standard things
.usage.enabled:0b
.clients.enabled:0b
.servers.enabled:0b;
.hb.enabled:0b;

\d .cmp
inputcsv:`$getenv[`KDBCONFIG],"/compressionconfig.csv"				// compression config file to use
hdbpath:`:hdb/database								// hdb directory
maxage:365									// the maximum date range of partitions to scan
exitonfinish:1b									// exit the process when compression is complete

// Bespoke Sort config : Finance Starter Pack

\d .wdb
savedir:hsym `$getenv[`KDBWDB]          // location to save wdb data
hdbdir:hsym`$getenv[`KDBHDB]		// move wdb database to different location
tickerplanttypes:sorttypes:()		// sort doesn't need these connections

\d .servers
CONNECTIONS:`hdb`rdb`gateway`sortworker        // list of connections to make at start up


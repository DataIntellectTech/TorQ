\d .servers
enabled:1b
CONNECTIONS:`qtp;   // Feedhandler connects to the query-tickerplant
HOPENTIMEOUT:30000

\d .
subprocs:"S"$read0 hsym `$(getenv `KDBCONFIG),"/querytrack.csv";        // List of procs for query-tickerplant to subscribe to

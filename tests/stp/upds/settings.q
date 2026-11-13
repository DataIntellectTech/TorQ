// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/stp/upds/process.csv";
stptestlogs:getenv[`KDBTESTS],"/stp/recovery/testlog";
stporiglogs:getenv[`KDBTPLOG];
testlogdb:"testlogdb";

// Test updates
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];

// Flag to save tests to disk
.k4.savetodisk:0b;

// Read the messages of a tickerplant log which call fn (upd, or upderr in the error log), by replaying it.
// get on a log file returns the messages on kdb+, but nothing on Korze
readlog:{[fn;f] `.tst.msgs set (); orig:@[value;fn;{{[t;x]}}]; fn set {[fn;t;x] .tst.msgs,:enlist(fn;t;x)}[fn]; r:@[{-11!x;1b};f;{x}]; fn set orig; if[not 1b~r;'r]; .tst.msgs};

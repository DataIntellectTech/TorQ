// IPC connection parameters
.servers.CONNECTIONS:`tickerplant`chainedtp`rdb;
.servers.USERPASS:`admin:admin;

// Test updates
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);

// Paths to process CSV and test TP log directory
processcsv:getenv[`KDBTESTS],"/chainedtp/process.csv";
tptestlogs:getenv[`KDBTESTS],"/chainedtp/tplogs";

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];

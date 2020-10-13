// IPC connection parameters
.servers.CONNECTIONS:`wdb`rdb`segmentedtickerplant`tickerplant;
.servers.USERPASS:`admin:admin;

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/stp/tpvalidation/process.csv";
temphdbdir:hsym `$getenv[`KDBTESTS],"/stp/tpvalidation/tmphdb/";
testlogdb:"testlog";

// Test updates
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];

// Get rid of some of the more egregious magic numbers
tincrease:10 5 10 5;
qincrease:10 0 10 0 10;
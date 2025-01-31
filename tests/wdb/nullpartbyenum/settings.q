// IPC connection parameters
.servers.CONNECTIONS:`wdb`segmentedtickerplant`tickerplant`hdb`idb`sort;
.servers.USERPASS:`admin:admin;

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/wdb/nullpartbyenum/process.csv";
wdbpartbyenumdir:hsym `$getenv[`KDBTESTS],"/wdb/nullpartbyenum/tempwdbpartbyenum/";
temphdbpartbyenumdir:hsym `$getenv[`KDBTESTS],"/wdb/nullpartbyenum/temphdbpartbyenum/";
testlogdb:"testlog";

// Test updates
testtrade:((3#`GOOG),``,5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:((8?`4),``;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);

// expected WDB folder structure
folder_patterns:{"*",x,"*"}each 1_/:string ` sv/:  cross[hsym each `$string til count distinct testtrade[0],testquote[0];`trade`quote];


// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];

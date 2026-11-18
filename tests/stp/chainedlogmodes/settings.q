// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant`segmentedchainedtickerplant;
.servers.USERPASS:`admin:admin;

// Test trade batches
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/stp/chainedlogmodes/process.csv";
testlogdb:"logmodeslog";

// Function projections (using functions from helperfunctions.q)
startproc:startorstopproc["start";;processcsv];
stopproc:startorstopproc["stop";;processcsv];

// End period function to send to subs
endp:{[x;y;z] .tst.endp:@[{1+value x};`.tst.endp;0]};

// Wait (up to 30 seconds) for the subscriber's next end of period, then reset its count to none. Each check below waits
// 11 seconds on a 10-second period and expects exactly one end of period: a wait that starts straight after one holds
// exactly one, while a wait that started at any time held two whenever a period ended in its first second
afterperiodend:{[h] c:h"@[value;`.tst.endp;-2]"; t:.z.p+0D00:00:30;
  while[(c~h"@[value;`.tst.endp;-2]") and .z.p<t; system "sleep 0.1"];
  h(set;`.tst.endp;-1)};

// Flag to save tests to disk
.k4.savetodisk:1b;

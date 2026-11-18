// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant`segmentedchainedtickerplant;
.servers.USERPASS:`admin:admin;

// Paths to process CSV and test STP log directory
processcsv:getenv[`KDBTESTS],"/stp/chainedperiodend/process.csv";
testlogdb:"testlog";

// Test updates
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);

// End period function to send to subs
endp:{[x;y;z] .tst.endp:@[{1+value x};`.tst.endp;0]};

// Flag to save tests to disk
.k4.savetodisk:1b;

// Wait up to 15 s for the tickerplant on handle h to roll its logs, so that the period the test measures is a whole
// one: the log opened at start-up (or by .stplg.init) starts part-way through a period
waitroll:{[h] i:h".stplg.i"; do[150; if[i<h".stplg.i"; :1b]; system"sleep 0.1"]; 0b};
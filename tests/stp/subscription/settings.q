// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Test trade batches
testtrade:((5#`GOOG),5?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;(5?50.0),50+5?50.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);

// Local trade table schema
trade:flip `time`sym`price`size`stop`cond`ex`side!"PSFIBCCS" $\: ();
quote:flip `time`sym`bid`ask`bsize`asize`mode`ex`src!"PSFFJJCCS" $\: ();

// Local upd and error log function
upd:{[t;x] t insert x};
upderr:{[t;x].tst.err:x};

// Test db name
testlogdb:"testlog";
// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Test trade batches
batch1:(10?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
batch2:(1?`4;1?100.0;1?100i;1#0b;1?.Q.A;1?.Q.A;1#`buy);

// Local trade table schema
trade:flip `time`sym`price`size`stop`cond`ex`side!"PSFIBCCS" $\: ();

// Local upd function
upd:{[t;x] t insert x};
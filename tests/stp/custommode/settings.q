// IPC connection parameters
.servers.CONNECTIONS:`rdb`segmentedtickerplant;
.servers.USERPASS:`admin:admin;

// Paths to process CSV and test/default STP log directory
tstlogs:getenv[`KDBTESTS],"/stp/custommode/tstlogs";
deflogs:getenv[`KDBTPLOG];

// Trade and quote schemas
trade:flip `time`sym`price`size`stop`cond`ex`side!"PSFIBCCS" $\: ();
quote:flip `time`sym`bid`ask`bsize`asize`mode`ex`src!"PSFFJJCCS" $\: ();

// Define upd functions for local tables and errors
upd:{[t;x] t insert x};
upderr:{[t;x] .tst.err:x};

// Couple of pre-defined strings
db:"stp1_",string .z.d;
proc:"stp1_";
liketabs:string[`segmentederrorlogfile`periodic`quote`stpmeta`heartbeat] ,\: "*";
liketabs:@[liketabs;0 1 2 4;{y,x}[;proc]];

// Test trade and quote updates
testtrade:(10?`4;10?100.0;10?100i;10#0b;10?.Q.A;10?.Q.A;10#`buy);
testquote:(10?`4;10?100.0;10?100.0;10?100i;10?100i;10?.Q.A;10?.Q.A;10#`3);
// IPC connection parameters
.servers.CONNECTIONS:`tickerlogreplay;
.servers.USERPASS:`admin:admin;

// Test HDB location
testhdb:getenv[`KDBTESTS],"/stp/tickerlog/testhdb/";
loadhdb:"l ",testhdb;

// Logs locations
oldelogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/oldlog/testoldlog";
fakelogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/oldlog/fakeoldlog";
nonelogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/stpnone";
perilogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/stptabperiod";
tabulogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/stptabular";
emptydir:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/nologs";
oldelogdir:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/oldlogdir";
zipfile:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/zipfile/testoldlog.gz";
zipdir:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/zipdir/";
zipdirstp:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/zipdirstp/";

// Reset and replay STP logs - to be executed on the tickerlog replay process
resplay:{[logdir]
  .replay.segmentedmode:1b;
  .replay.tplogfile:`;
  .replay.tplogdir:logdir;
  .replay.initandrun[];
 };

// Reset to old TP mode and only replay quote table logs
oldify:{[logfile]
  .replay.segmentedmode:0b;
  .replay.tablelist:`quote;
  .replay.tablestoreplay:`quote,();
  .replay.tplogfile:logfile;
  .replay.tplogdir:`;
  .replay.initandrun[];
 };

// Reset to old TP mode and play in a log directory
olddir:{[logdir]
  .replay.segmentedmode:0b;
  .replay.tplogfile:`;
  .replay.tplogdir:logdir;
  .replay.initandrun[];
 };

// Reset and try to load file
oldfile:{[logfile]
  .replay.segmentedmode:0b;
  .replay.tplogfile:logfile;
  .replay.tplogdir:`;
  .replay.initandrun[];
 };

// Reset and try to load in a file while in segmented mode
segfile:{[logfile]
  .replay.segmentedmode:1b;
  .replay.tplogfile:logfile;
  .replay.tplogdir:`;
  .replay.initandrun[];
 };

// Reset and try to load in a file and a directory at the same time
dirandfile:{[logfile]
  .replay.tplogfile:logfile;
  .replay.tplogdir:logfile;
  .replay.initandrun[];
 };

// Change meta table lognames to match local testing setup
localise:{[logpath]
  metatable:get tabpath:.Q.dd[logpath;`stpmeta];
  logpaths:.Q.dd[logpath;] each `$last each exec "/" vs' string logname from metatable;
  tabpath set update logname:logpaths from metatable;
 };
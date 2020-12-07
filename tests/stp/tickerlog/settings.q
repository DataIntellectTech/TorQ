// IPC connection parameters
.servers.CONNECTIONS:`tickerlogreplay;
.servers.USERPASS:`admin:admin;

// Test HDB location
testhdb:getenv[`KDBTESTS],"/stp/tickerlog/testhdb/";
loadhdb:"l ",testhdb;

// Logs locations
oldelogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/oldlog/testoldlog";
nonelogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/stpnone";
perilogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/stptabperiod";
tabulogs:hsym `$getenv[`KDBTESTS],"/stp/tickerlog/logs/stptabular";

// Reset and replay STP logs - to be executed on the tickerlog replay process
resplay:{[logfile]
  .replay.segmentedmode:1b;
  .replay.tplogfile:logfile;
  .replay.initandrun[];
 };

// Reset to old TP mode and only replay quote table logs
oldify:{[logfile]
  .replay.segmentedmode:0b;
  .replay.tablelist:`quote;
  .replay.tablestoreplay:`quote,();
  .replay.tplogfile:logfile;
  .replay.initandrun[];
 };

// Change meta table lognames to match local testing setup
localise:{[logpath]
  metatable:get tabpath:.Q.dd[logpath;`stpmeta];
  logpaths:.Q.dd[logpath;] each `$last each exec "/" vs' string logname from metatable;
  tabpath set update logname:logpaths from metatable;
 };
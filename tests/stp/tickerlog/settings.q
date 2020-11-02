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
  .replay.clean:0b;
  .replay.segmentedmode:1b;
  .replay.tplogfile:logfile;
  .replay.logstoreplay:.replay.expandstplogs[.replay.tplogfile];
  .replay.replaylog each .replay.logstoreplay;
 };

// Reset to old TP mode and only replay quote table logs
oldify:{[logfile]
  .replay.segmentedmode:0b;
  .replay.tablelist:`quote;
  .replay.tablestoreplay:`quote,();
  .replay.tplogfile:logfile;
  .replay.logstoreplay:enlist hsym logfile;
  .replay.replaylog each .replay.logstoreplay;
 };
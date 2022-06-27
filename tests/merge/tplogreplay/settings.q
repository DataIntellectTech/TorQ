// ipc connection handlers
.servers.CONNECTIONS:`discovery`hdb;
.servers.USERPASS:`admin:admin;
// need the upd to reload log files to memory 
upd:{[t;x] t insert x}
//variables needed to run log replay system commands below 
tempdir:getenv[`KDBTESTS],"/merge/tplogreplay/tempmergedir"
hdbdir:getenv[`KDBTESTS],"/merge/tplogreplay/testhdb"
schemafile:getenv[`KDBTESTS],"/merge/tplogreplay/database.q"
tplogdir:getenv[`KDBTESTS],"/merge/tplogreplay/testlogs"
processfile:getenv[`KDBCODE],"/processes/tickerlogreplay.q"
testconfig:getenv[`KDBTESTS],"/merge/tplogreplay/treplaysettings.q"

// system commands to run tickerlogreplay script with different merge methods
colreplay:{system"q torq.q -debug -load ",processfile," ",testconfig," -.replay.tplogdir ",tplogdir," -.replay.hdbdir ",hdbdir," -.replay.schemafile ", schemafile," -.replay.mergemethod col -proctype tickerlogreplay -procname tplogreplay1"};
partreplay:{system"q torq.q -debug -load ",processfile," ",testconfig," -.replay.tplogdir ",tplogdir," -.replay.hdbdir ",hdbdir," -.replay.schemafile ", schemafile," -.replay.mergemethod part -proctype tickerlogreplay -procname tplogreplay1"};
hybridreplay:{system"q torq.q -debug -load ",processfile," ",testconfig," -.replay.tplogdir ",tplogdir," -.replay.hdbdir ",hdbdir," -.replay.schemafile ", schemafile," -.replay.mergemethod hybrid -proctype tickerlogreplay -procname tplogreplay1"};

//.replay variables needed to load tickerlogreplay script
.replay.autoreplay:0b
.replay.tplogdir: `$tplogdir
.replay.hdbdir: `$hdbdir
.replay.schemafile: `$schemafile
//dropping the tables that are not replayed by log files needed to get use function for names of stp logs
.replay.tablestoreplay:3_tables[]

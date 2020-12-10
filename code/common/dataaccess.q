//- common script to enable remote data access via generic function
//- loads in scripts from code/common/dataaccess

\d .dataaccess

settablepropertiespath:{[]resettablepropertiespath hsym`$first .proc.params`dataaccess};
resettablepropertiespath:{[tablepropertiespath]`.dataaccess.tablepropertiespath set tablepropertiespath};
validtablepropertiespath:{[].dataaccess.tablepropertiespath~key .dataaccess.tablepropertiespath};
checkinputspath:first .proc.getconfigfile"checkinputs.csv";

procmetainfo:([procname:`$();proctype:`$()];w:`int$();metainfo:());
metainfo:([tablename:`$()]partitionfield:`$();hdbparams:();rdbparams:());

//- initnewconnection takes:
//- (i) tablepropertiespath - either from a valid -dataaccess path from cmd line, or passed explicitly
//- (ii) connectiontab - for updating meta info when a new connection is made.
//- otherwise a user can call "init[`:/path/to/tableproperties.csv]"
initnewconnection:{[tablepropertiespath;connectiontab]
  .lg.o[`.dataaccess.init;"running .dataaccess.initnewconnection"];
  .proc.loaddir getenv[`KDBCODE],"/dataaccess";
  .servers.retry[];
  if[not validtablepropertiespath[];resettablepropertiespath tablepropertiespath];
  if[()~key`.dataaccess.tablepropertiesconfig;`.dataaccess.tablepropertiesconfig set readtableproperties tablepropertiespath];
  if[()~key`.dataaccess.checkinputsconfig;`.dataaccess.checkinputsconfig set readcheckinputs checkinputspath];
  `.dataaccess.procmetainfo upsert getprocmetainfo connectiontab;
  `.dataaccess.metainfo set getmetainfo .dataaccess.procmetainfo; 
  .lg.o[`.dataaccess.init;"running .dataaccess.initnewconnection - finished"];
 };

//- call "init[`:/path/to/tableproperties.csv]"
init:initnewconnection[;`.server.SERVERS];

connectcustom:{[f;connectiontab]
  @[f;connectiontab;()];
  .[.dataaccess.initnewconnection;(.dataaccess.tablepropertiespath;connectiontab);()];
 }@[value;`.servers.connectcustom;{{[x]}}]

\d .

.dataaccess.settablepropertiespath[];

.z.pc:{[f;x]
  @[f;x;()];
  if[.dataaccess.validtablepropertiespath[];delete from`.dataaccess.procmetainfo where w=x];
 }@[value;`.z.pc;{{}}];

//- ***WIP
if[.dataaccess.validtablepropertiespath[];.servers.connectcustom:.dataaccess.connectcustom];

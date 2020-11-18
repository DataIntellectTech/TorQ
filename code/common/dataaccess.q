//- common script to enable remote data access via generic function
//- loads in scripts from code/common/dataaccess

\d .dataaccess

settablepropertiespath:{[]resettablepropertiespath hsym`$first .proc.params`dataaccess};
resettablepropertiespath:{[tablepropertiespath]`.dataaccess.tablepropertiespath set tablepropertiespath};
validtablepropertiespath:{[].dataaccess.tablepropertiespath~key .dataaccess.tablepropertiespath};
checkinputspath:first .proc.getconfigfile"checkinputs.csv";

metainfo:([tablename:`$()]partitionfield:`$();hdbparams:();rdbparams:());

//- initnewconnection takes:
//- (i) tablepropertiespath - either from a valid -dataaccess path from cmd line, or passed explicitly
//-                           otherwise a user can call "init[`:/path/to/tableproperties.csv]"
//- call "init[`:/path/to/tableproperties.csv]"

init:{[tablepropertiespath]
  .lg.o[`.dataaccess.init;"running .dataaccess.initnewconnection"];
  .proc.loaddir getenv[`KDBCODE],"/dataaccess";
  if[not validtablepropertiespath[];resettablepropertiespath tablepropertiespath];
  if[()~key`.dataaccess.tablepropertiesconfig;`.dataaccess.tablepropertiesconfig set readtableproperties tablepropertiespath];
  if[()~key`.dataaccess.checkinputsconfig;`.dataaccess.checkinputsconfig set readcheckinputs checkinputspath];
  `.dataaccess.metainfo upsert getprocmetainfo[];
  .lg.o[`.dataaccess.init;"running .dataaccess.initnewconnection - finished"];
 };

\d .

.dataaccess.settablepropertiespath[];

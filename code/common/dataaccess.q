//- common script to enable remote data access via generic get data function

\d .dataaccess

// to set table properties path passed from -dataaccess parameter
settablepropertiespath:{[]resettablepropertiespath hsym`$first .proc.params`dataaccess};
// to set table properties path from given path
resettablepropertiespath:{[tablepropertiespath]`.dataaccess.tablepropertiespath set tablepropertiespath};
// to check if table properties config file exists at given path
validtablepropertiespath:{[].dataaccess.tablepropertiespath~key .dataaccess.tablepropertiespath};
// get path to config file for checking data api input parameters
checkinputspath:first .proc.getconfigfile"checkinputs.csv";

// instantiate table for holding table metas of current proccess
metainfo:([tablename:`$()]partfield:`$();metas:();proctype:`$());

//- init function takes:
//- (i) tablepropertiespath - either from a valid -dataaccess path from cmd line, or passed explicitly
//-                           otherwise a user can call "init[`:/path/to/tableproperties.csv]"
//- init will:
//-   - load data access code from code/common dataaccess
//-   - validate table properties config file exists + load it 
//-   - load config for checking input parameters
//-   - write meta info for tables in current process to .dataaccess.metainfo

init:{[tablepropertiespath]
  .lg.o[`.dataaccess.init;"running .dataaccess.init"];
  .proc.loaddir getenv[`KDBCODE],"/dataaccess";
  if[not validtablepropertiespath[];resettablepropertiespath tablepropertiespath];
  if[()~key`.dataaccess.tablepropertiesconfig;`.dataaccess.tablepropertiesconfig set readtableproperties tablepropertiespath];
  if[()~key`.dataaccess.checkinputsconfig;`.dataaccess.checkinputsconfig set readcheckinputs checkinputspath];
  `.dataaccess.metainfo upsert getmetainfo[];
  .lg.o[`.dataaccess.init;"running .dataaccess.init - finished"];
 };

connectcustom:{[f;connectiontab]
  @[f;connectiontab;()];
  @[.dataaccess.init;.dataaccess.tablepropertiespath;()];
 }@[value;`.servers.connectcustom;{{[x]}}]

\d .

if[.proc.proctype in `rdb`hdb;
  // set table properties path
  .dataaccess.settablepropertiespath[];
  // initialize dataaccess code
  .dataaccess.init .dataaccess.tablepropertiespath;
  // add initializing of dataaccess code upon new connection
  if[.dataaccess.validtablepropertiespath[];.servers.connectcustom:.dataaccess.connectcustom];
  ];

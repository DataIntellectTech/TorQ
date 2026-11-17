//- common script to enable remote data access via generic get data function

\d .dataaccess

//set the default tableproperties path to ` allow initialisation intra-process
tablepropertiespath:@[value;`.dataaccess.tablepropertiespath;`]

// to set table properties path passed from -dataaccess parameter
settablepropertiespath:{[]
  if[not`dataaccess in key .proc.params;.lg.e[`.dataaccess.settablepropertiespath;"No table properties passed by -dataaccess parameter"]];
  resettablepropertiespath hsym`$first .proc.params`dataaccess;
 };
// to set table properties path from given path
resettablepropertiespath:{[tablepropertiespath]`.dataaccess.tablepropertiespath set tablepropertiespath};
// to check if table properties config file exists at given path
validtablepropertiespath:{[].dataaccess.tablepropertiespath~key .dataaccess.tablepropertiespath};
// get path to config file for checking data api input parameters
checkinputspath:first .proc.getconfigfile"dataaccess/checkinputs.csv";

// instantiate table for holding table metas of current process
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
  if[@[value;`.aqrest.loadexecute;0b];.aqrest.execute:{[req;props] @[value;req;{(neg .z.w)(.gw.formatresponse[0b;0b;"error: ",x])}]}];
  .lg.o[`.dataaccess.init;"running .dataaccess.init"];
  .proc.loaddir getenv[`KDBCODE],"/dataaccess";
  if[not validtablepropertiespath[];resettablepropertiespath tablepropertiespath];
  if[()~key`.checkinputs.tablepropertiesconfig;`.checkinputs.tablepropertiesconfig set .checkinputs.readtableproperties tablepropertiespath];
  if[()~key`.checkinputs.checkinputsconfig;`.checkinputs.checkinputsconfig set .checkinputs.readcheckinputs checkinputspath];
  `.dataaccess.metainfo upsert .checkinputs.getmetainfo[];
  // Check if all the tables presented in tableproperties.csv have been 
  if[.proc.proctype=`hdb;
      if[not all(exec tablename from .checkinputs.readtableproperties[.dataaccess.tablepropertiespath] where proctype in `hdb`all`) in exec tablename from .dataaccess.metainfo;
          .lg.e[`.dataaccess.init;"Missing table from HDB in schema"]]];
  .lg.o[`.dataaccess.init;"running .dataaccess.init - finished"];
 };

// init at the end of start-up: a failure is only logged, as it is when init runs on a new connection (an error in the
// init list would stop the process)
startupinit:{[tablepropertiespath] @[init;tablepropertiespath;{.lg.w[`.dataaccess.init;"could not initialise the data access API: ",x]}]};

// 1b when discovery is off. TorQ turns it off under a connection limit, such as KDB-X's free licence (DISCOVERYCONNECT
// in config/settings/default.q), and then a process may make no connection at all, so init, which runs on each new
// connection, would never run
nodiscovery:{[] not @[value;`.servers.DISCOVERYCONNECT;1b]};

connectcustom:{[f;connectiontab]
  @[f;connectiontab;()];
  @[.dataaccess.init;.dataaccess.tablepropertiespath;()];
 }@[value;`.servers.connectcustom;{{[x]}}]

\d .

if[`dataaccess in key .proc.params;
  // set table properties path
  .dataaccess.settablepropertiespath[];
  // re-initialize on new connections 
  if[.dataaccess.validtablepropertiespath[];.servers.connectcustom:.dataaccess.connectcustom];
  // and, with discovery off, once start-up has finished (see nodiscovery)
  if[.dataaccess.validtablepropertiespath[] and .dataaccess.nodiscovery[];.proc.addinitlist(`.dataaccess.startupinit;.dataaccess.tablepropertiespath)];
  ];

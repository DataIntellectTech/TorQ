// Segmented TP process
// Contains all TP functionality with additional flexibility
// Configurable logging and subscriptions
// Default settings create single TP log per table and rolls logs hourly
// Subscription to a table can be made in two modes - all or filtered
// All - publish all data for table
// Filtered - apply filters to published data, filters defined on client side

createlogs:@[value;`createlogs;1b]; // allow tickerplant to create a log file

// subscribers use this to determine what type of process they are talking to
tptype:`segmented

.proc.loadf[getenv[`KDBCODE],"/common/os.q"];
.proc.loadf[getenv[`KDBCODE],"/common/timezone.q"];
.proc.loadf[getenv[`KDBCODE],"/common/eodtime.q"];

// In singular or tabular mode, intraday rolling not required
if[.stplg.multilog in `singular`tabular;.stplg.multilogperiod:1D];

// In custom mode, load logging type for each table
if[.stplg.multilog~`custom;
  @[{.stplg.custommode:1_(!) . ("SS";",")0: x};.stplg.customcsv;{.lg.e[`stp;"failed to load custom mode csv"]}]
 ];

// functions used by subscribers
tablelist:{.stpps.t}

// Subscribers who want to replay need this info
subdetails:{[tabs;instruments]
 `schemalist`logfilelist`rowcounts`date`logdir!(.ps.subscribe\:[tabs;instruments];.stplg.replaylog[tabs];((),tabs)#.stplg `rowcount;(.eodtime `d);`$getenv`KDBTPLOG)
 }

// Generate table and schema information and set up default table UPD functions
generateschemas:{
  .stpps.init[tables[] except `currlog];
  .stpps.attrstrip[.stpps.t];

  // Table UPD functions attach the current timestamp by default, if STP is chained these do nothing
  $[.sctp.chainedtp;
    .stplg.updtab:(.stpps.t!(count .stpps.t)#{[x;y] x}),.stplg.updtab;
    .stplg.updtab:(.stpps.t!(count .stpps.t)#{(enlist(count first x)#y),x}),.stplg.updtab
    ]
  }

// Load in schema file and kill proc if not present
loadschemas:{
  if[not `schemafile in key .proc.params;.lg.e[`loadschema;"Schema file required!"];exit 1];
  @[.proc.loadf;raze .proc.params[`schemafile];{.lg.e[`loadschema;"Failed to load schema file!"];exit 1}];
 };

// Set up UPD and ZTS behaviour based on batching mode
setup:{[batch]
  // Handle bad batch mode, see whether STP is chained or default
  if[not all batch in/: key'[.stplg`upd`zts];'"mode ",(string batch)," must be defined in both .stplg.upd and .stplg.zts"];
  chainmode:$[.sctp.chainedtp;`chained;`def];

  // Set inner UPD and ZTS behaviour from batch mode, then set outer functions based on whether STP is chained
  .stplg.updmsg:.stplg.upd[batch];
  .stplg.ts:.stplg.zts[batch];
  .u.upd:.stpps.upd[chainmode];
  .z.ts:.stpps.zts[chainmode];
  
  // Error mode - error trap UPD to write failed updates to separate TP log
  if[.stplg.errmode;
    .stp.upd:.u.upd;
    .u.upd:{[t;x] .[.stp.upd;(t;x);{.stplg.badmsg[x;y;z]}[;t;x]]}
   ];

  // Default the timer to 1 second if not set
  if[not system "t";.lg.o[`timer;"defaulting timer to 1000ms"];system"t 1000"];
 };

// Initialise process
init:{
  // Set up the update and publish functions
  setup[.stplg.batchmode];
  // If process is a chained STP then subscribe to the main STP, if not, load schema file
  $[.sctp.chainedtp;.sctp.init[];loadschemas[]];
  // Set up pubsub mechanics and table schemas
  generateschemas[];
  // Set up logs and log handles using name of process as an identifier
  .stplg.init[string .proc.procname];
 };

//Loads the striping.json config file checks if each subscriptiondefault is set for each segment and errors if not defined
jsonchecks:{[scpath]
     .stpps.stripeconfig:@[{.j.k read1 x};scpath;{.lg.e[`configcheck;"Failed to load in json file: ",x]}];
     // check defaults are ignore or all
     defaults:{first (flip .stpps.stripeconfig[x])[`subscriptiondefault]}each key .stpps.stripeconfig;
     errors:1+ where {[x] not ("ignore"~x) or ("all"~x)}each defaults;
     {if[0<count x;.lg.o[`configcheck;m:"subscriptiondefault not defined as \"ignore\" or \"all\" for segment ",string[x]," "]]}each errors;
     // check for valid tables
     keydict: key(flip .stpps.stripeconfig[`segid]);
     stripedtables: .stpps.t inter keydict;
     wrongtables:(keydict except `subscriptiondefault) except stripedtables;
     {if[0<count x;.lg.o[`sub;m:"Table ",string[x]," is not recognised"]]}each wrongtables;
     //Enable datastriping if all checks pass
     $[min (0=count errors; 0=count wrongtables);(.lg.o[`configcheck;"config checks complete and datastriping is on"];.ds.datastripe:1b);.lg.o[`configcheck;"config checks error"]];
     };
configcheck:{
     .lg.o[`configcheck;"initiate config check"];
     scpath:first .proc.getconfigfile[string .ds.stripeconfig];
     // Check striping.json file exists then check if empty
     $[()~key hsym scpath; .lg.o[`configcheck;"The following file can not be found: ",string scpath];$[()~read0 scpath; .lg.o[`configcheck;"The following file is empty: ",string scpath]; jsonchecks[scpath]]]
     };

// Have the init function called from torq.q
.proc.addinitlist(`init;`);
.proc.addinitlist(`configcheck;`);

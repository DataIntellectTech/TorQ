// Segmented TP process
// Contains all TP functionality with additional flexibility
// Configurable logging and subscriptions
// Default settings create single TP log per table and rolls logs hourly
// Subscription to a table can be made in two modes - all or filtered
// All - publish all data for table
// Filtered - apply filters to published data, filters defined on client side

chainedtp:@[value;`chainedtp;0b];  /- sets process up as a chained segmented tickerplant

/ below variables only apply when process is set up as a Chained TP
tickerplantname:@[value;`tickerplantname;`stp1];                /- tickerplant name to try and make a connection to  
createlogs:@[value;`createlogs;1b];                             /- allow chained tickerplant to create a log file
subscribeto:@[value;`subscribeto;`];                            /- list of tables to subscribe for
subscribesyms:@[value;`subscribesyms;`];                        /- list of syms to subscription to
replay:@[value;`replay;0b];                                     /- replay the tickerplant log file
schema:@[value;`schema;1b];                                     /- retrieve schema from tickerplant


// subscribers use this to determine what type of process they are talking to
tptype:`segmented

.proc.loadf[getenv[`KDBCODE],"/common/os.q"];
.proc.loadf[getenv[`KDBCODE],"/common/timezone.q"];
.proc.loadf[getenv[`KDBCODE],"/common/eodtime.q"];

if[chainedtp;[
  .proc.loadf[getenv[`KDBCODE],"/common/timer.q"];
  .proc.loadf[getenv[`KDBCODE],"/common/subscriptions.q"];
  ]];

// Load schema
$[`schemafile in key .proc.params;
  .proc.loadf[schemafile:raze .proc.params[`schemafile]];
  [.lg.e[`stp;"schema file required"];exit 1]
 ]

// Populate pub/sub tables list with schema tables
.stpps.t:tables[]except `currlog;
.stpps.schemas:.stpps.t!value each .stpps.t;

// amend the main schemas to not have any attributes
{@[x;cols x;`#]}each .stpps.t;

// store attribute free empty versions of the tables
.stpps.schemasnoattributes:.stpps.t!value each .stpps.t

// updtab stores functions to add/modify columns
// Default functions timestamp updates
// Preserve any prior definitions, but default all tables if not specified
.stplg.updtab:(.stpps.t!(count .stpps.t)#{(enlist(count first x)#y),x}),.stplg.updtab

// In none or tabular mode, intraday rolling not required
if[.stplg.multilog in `none`tabular;.stplg.multilogperiod:1D];

// In custom mode, load logging type for each table
if[.stplg.multilog~`custom;
  @[{.stplg.custommode:1_(!) . ("SS";",")0: x};.stplg.customcsv;
    {.lg.e[`stp;"failed to load custom mode csv"]}]
 ];

// functions used by subscribers
tablelist:{.stpps.t}
// subscribers who want to replay need this info 
subdetails:{[tabs;instruments]
 `schemalist`logfilelist`rowcounts`date`logdir!(.u.sub\:[tabs;instruments];.stplg.replaylog[tabs];tabs#.stplg `rowcount;(.eodtime `d);`$getenv`KDBSTPLOG)}

init:{[b]
  if[not all b in/:(key .stplg.upd;key .stplg.zts);'"mode ",(string b)," must be defined in both .stplg.upd and .stplg.zts"];
  .u.init[.stpps.t];
  .stplg.updmsg:.stplg.upd[b];
  .u.upd:{[t;x]
    // snap the current time and check for period end
    if[.stplg.nextendUTC<now:.z.p and not chainedtp;.stplg.checkends now];
    // Type check allows update messages to contain multiple tables/data
    $[0h<type t;
      .stplg.updmsg'[t;x;now+.eodtime.dailyadj];
      .stplg.updmsg[t;x;now+.eodtime.dailyadj]
    ];
    .stplg.seqnum+:1;
  };
  // set .z.ts to execute the timer func and then check for end-of-period/end-of-day
  .stplg.ts:.stplg.zts[b];
  .z.ts:{
    .stplg.ts now:.z.p; 
    if[not chainedtp;.stplg.checkends now]};
  // Error mode - write failed updates to separate TP log
  if[.stplg.errmode;
    //.stplg.openlogerr[.stplg.dldir]; - this is being done in .stplg.init now
    .stp.upd:.u.upd;
    .u.upd:{[t;x] .[.stp.upd;(t;x);{.stplg.badmsg[x;y;z]}[;t;x]]}
  ];
  // default the timer if not set
  if[not system"t"; 
   .lg.o[`timer;"defaulting timer to 1000ms"];
    system"t 1000"];
 };

// Initialise process

\d .u
init:{w::t!(count t::x)#()}          // altered definition of .u.init for tables in .stpps.t

// CTP functions

\d .

upd:{[t;x]
  if[not chainedtp; :()];
  // extract data from incoming table as a list
  x:flip value each x;
  .u.upd[t;x]
 }

/- subscribe to segmented tickerplant
subscribe:{[]
  s:.sub.getsubscriptionhandles[`;tickerplantname;()!()];
  if[count s;
      subproc:first s;
      tph:subproc`w;
      /- get tickerplant date - default to today's date
      .lg.o[`subscribe;"subscribing to ", string subproc`procname];
      r:.sub.subscribe[subscribeto;subscribesyms;schema;replay;subproc];
      if[`d in key r;.u.d::r[`d]]; 
      if[(`icounts in key r) & (not createlogs); /- dict r contains icounts & not using own logfile
        subtabs:$[subscribeto~`;key r`icounts;subscribeto],();
        .u.jcounts::.u.icounts::$[0=count r`icounts;()!();subtabs!enlist [r`icounts]subtabs];
      ]
    ];
  }

// Create log directory, open all table logs
// use name of schema to create directory
.stplg.init[dbname:-2 _ last "/" vs schemafile]

// Set update and publish modes
init[.stplg.batchmode]

.servers.startup[];

/- subscribe to segmented tickerplant is mode is turned on
if[chainedtp; subscribe[] ]

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

$[.sctp.chainedtp;[
  .proc.loadf[getenv[`KDBCODE],"/common/timer.q"];
  .proc.loadf[getenv[`KDBCODE],"/common/subscriptions.q"];
  schemafile:""
  ];
  // Load schema
  $[`schemafile in key .proc.params;
    .proc.loadf[schemafile:raze .proc.params[`schemafile]];
    [.lg.e[`stp;"schema file required"];exit 1]
   ]
  ];

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


generateschemas:{
  // Populate pub/sub tables list with schema tables
  //stpHandle: exec w from .servers.SERVERS where proctype=`segmentedtickerplant
  .stpps.t:tables[]except `currlog;
  .stpps.schemas:.stpps.t!value each .stpps.t;

  // amend the main schemas to not have any attributes
  {@[x;cols x;`#]}each .stpps.t;

  // store attribute free empty versions of the tables
  .stpps.schemasnoattributes:.stpps.t!value each .stpps.t;

  // updtab stores functions to add/modify columns
  // Default functions timestamp updates
  // Preserve any prior definitions, but default all tables if not specified
  $[.sctp.chainedtp;
    .stplg.updtab:(.stpps.t!(count .stpps.t)#{[x;y] x}),.stplg.updtab;
    .stplg.updtab:(.stpps.t!(count .stpps.t)#{(enlist(count first x)#y),x}),.stplg.updtab
    ]
  }


init:{[b]
  if[not all b in/:(key .stplg.upd;key .stplg.zts);'"mode ",(string b)," must be defined in both .stplg.upd and .stplg.zts"];
  .stplg.updmsg:.stplg.upd[b];
  $[.sctp.chainedtp;
    .u.upd:{[t;x]
      now:.z.p;
      // Type check allows update messages to contain multiple tables/data
      $[0h<type t;
        .stplg.updmsg'[t;x;now+.eodtime.dailyadj];
        .stplg.updmsg[t;x;now+.eodtime.dailyadj]
      ];
      .stplg.seqnum+:1;
      };
    .u.upd:{[t;x]
      // snap the current time and check for period end
      if[.stplg.nextendUTC<now:.z.p;.stplg.checkends now];
      // Type check allows update messages to contain multiple tables/data
      $[0h<type t;
        .stplg.updmsg'[t;x;now+.eodtime.dailyadj];
        .stplg.updmsg[t;x;now+.eodtime.dailyadj]
      ];
      .stplg.seqnum+:1;
      }
    ];
  // set .z.ts to execute the timer func and then check for end-of-period/end-of-day
  .stplg.ts:.stplg.zts[b];
  $[.sctp.chainedtp;
    .z.ts:{
      .stplg.ts now:.z.p;
      };
    .z.ts:{
      .stplg.ts now:.z.p; 
      .stplg.checkends now
      }
    ];
  
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

\d .

// Set update and publish modes
init[.stplg.batchmode]

// subscribe to segmented tickerplant is mode is turned on
if[.sctp.chainedtp;
  endofperiod:{[x;y;z] .stplg.endofperiod[x;y;z]};
  endofday:{[x;y] .stplg.endofday[x;y]};
  .servers.startup[]; 
  .sctp.subscribe[]
  ]

// produces schema dicts/tables and upd functions
// executed after .sctp.subscribe since the SCTP grabs the schemas from the STP
generateschemas[];

// Create log directory, open all table logs
// use name of schema to create directory
`dbname set (string .proc.procname);
.stplg.init[dbname]

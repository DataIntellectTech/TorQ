// Segmented TP process
// Contains all TP functionality with additional flexibility
// Configurable logging and subscriptions
// Default settings create single TP log per table and rolls logs hourly
// Subscription to a table can be made in two modes - all or filtered
// All - publish all data for table
// Filtered - apply filters to published data, filters defined on client side

.proc.loadf[getenv[`KDBCODE],"/common/os.q"];

// Load schema
$[`schemafile in key .proc.params;
  .proc.loadf[raze .proc.params[`schemafile],".q"];
  [.lg.e[`stp;"schema file required"];exit]
 ]

// Populate pub/sub tables list with schema tables
.stpps.t:tables`.;

// updtab stores functions to add/modify columns
// Default functions timestamp updates
// TO DO - add function to load user-sepcified updtab funcs
@[`.stpps.updtab;.stpps.t;:;{(enlist(count first x)#.z.p),x}];

// In none or tabular mode, intraday rolling not required
if[.stplg.multilog in `none`tabular;.stplg.multilogperiod:1D]

// In custom mode, load logging type for each table
if[.stplg.multilog~`custom;.stplg.custommode:1_(!) . ("SS";",")0: .stplg.customcsv]

init:{[b]
  .u.upd:{[b;t;x]
    .stplg.totalmsgcount+:1;
    // Type check allows update messages to contain multiple tables/data
    $[0h<type t;.stplg.upd[b]'[t;x];.stplg.upd[b][t;x]]
    @[`.stplg.msgcount;t;+;1];
  }[b;;];
  .z.ts:.stplg.zts[b];
  // Error mode - write failed updates to separate TP log
  if[.stplg.errmode;
    .stplg.openlogerr[.stplg.dldir];
    .stplg.handles::.stplg.handles,exec tbl!handle from .stplg.currlog where tbl=`err;
    .stp.upd:.u.upd;
    .u.upd:{[t;x] .[.stp.upd;(t;x);{.stplg.badmsg[x;y;z]}[;t;x]]}
  ];
 };

// Initialise process

// Create log directory, open all table logs, define logging period
.stplg.init[]

// Set update and publish modes
init[.stplg.batchmode]

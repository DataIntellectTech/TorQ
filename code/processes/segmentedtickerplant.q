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

// Timer function in batch mode
.z.ts:{
  // Publish data to handles in .stpps.subrequestall and .stpps.subrequestfiltered
  .stpps.pub'[.stpps.t;value each .stpps.t];
  @[`.;.stpps.t;@[;`sym;`g#]0#];
  // Initiates log rollover if end of period exceeded
  .stplg.ts .z.p
 };

.u.upd:{[t;x]
  if[.z.p>.eodtime.nextroll;.z.ts[]];
  x:.stpps.updtab[t]@x;
  t insert x;
  .stpps.msgcount[t]+::count first x;
  // Find appropriate log for update
  if[not null h:(w:.stplg.whichlog[t;x])`handle;
    h enlist(`upd;t;w[`data])
  ];
 };

// Initialise process
// Creates log directory, opens all table logs, defines logging period

.stplg.init[]

// Error mode - write failed updates to separate TP log
if[.stplg.errmode;
  .stplg.openlogerr[.stplg.dldir];
  .stp.upd:.u.upd;
  .u.upd:{[t;x] .[.stp.upd;(t;x);{.stplg.badmsg[x;y;z]}[;t;x]]}
 ]


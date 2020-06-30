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

init:{[t]
  if[t;
    // Timer function in batch mode
    // If .stplg.batchmode set, publish and write to disk in batches
    // Otherwise, publish in batch, write immediately
    $[.stplg.batchmode;
      [.z.ts:{
        // Publish data to handles in .stpps.subrequestall and .stpps.subrequestfiltered
        .stpps.pub'[.stpps.t;value each .stpps.t];
        // Disk write for all tables
        {[t;x].stplg.handles[t] enlist(`upd;t;x)}'[.stplg.t;value each .stplg.t];
        @[`.;.stpps.t;@[;`sym;`g#]0#];
        // Initiates log rollover if end of period exceeded
        .stplg.ts .z.p
      };
      .u.upd:{[t;x]
        if[.z.p>.eodtime.nextroll;.z.ts[]];
        x:.stpps.upd[t;x];
        .stplg.msgcount[t]+::1;
      }];
      [.z.ts:{
        .stpps.pub'[.stpps.t;value each .stpps.t];
        @[`.;.stpps.t;@[;`sym;`g#]0#];
        .stplg.ts .z.p
      };
      .u.upd:{[t;x]
        if[.z.p>.eodtime.nextroll;.z.ts[]];
        x:.stpps.upd[t;x];
        .stplg.msgcount[t]+::1;
        .stplg.handles[t] enlist(`upd;t;x)
      }]
    ];
  ];
  if[not t;
    // Immediate mode - publish and write immediately
    .z.ts:{.stplg.ts .z.p};
    .u.upd:{[t;x]
      .stplg.ts .z.p;
      x:.stpps.upd[t;x];
      .stplg.msgcount[t]+::1;
      .stplg.handles[t] enlist(`upd;t;x);
      .stpps.pub[t;x];
      @[`.;t;@[;`sym;`g#]0#];
    };
  ];
  // Error mode - write failed updates to separate TP log
  if[.stplg.errmode;
    .stplg.openlogerr[.stplg.dldir];
    .stplg.handles::.stplg.handles,exec tbl!handle from .stplg.currlog where tbl=`err;
    .stp.upd:.u.upd;
    .u.upd:{[t;x] .[.stp.upd;(t;x);{.stplg.badmsg[x;y;z]}[;t;x]]}
  ];
 };


// Initialise process

// Creates log directory, opens all table logs, defines logging period
.stplg.init[]

// Set update and publish modes
init[system"t"]

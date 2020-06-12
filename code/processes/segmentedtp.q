// Segmented TP process
// Contains all TP functionality with additional flexibility
// Configurable logging and subscriptions

.proc.loadf[getenv[`KDBCODE],"/common/os.q"];
.proc.loadf[getenv[`KDBCODE],"/segmentedtp"];

.z.ts:{
  .stpps.pub'[.stpps.t;value each .stpps.t];
  @[`.;.stpps.t;@[;`sym;`g#]0#];
  .stplg.ts .z.p
 };

.u.upd:{[t;x]
  if[not -12=type first first x;
    if[.z.p>.eodtime.nextroll;.z.ts[]];
    x:.stpps.updtab[t]@x
  ];
  t insert x;
  .stpps.msgcount[t]+::count first x;
  if[t in key .stplg.currlog;
    w:.stplg.whichlog[t;x];
    w[`handle] enlist(`upd;t;w[`data])
  ];
 };

.eodtime.nextperiod:.eodtime.getperiod[.z.p;.stplg.multilogperiod]

.stplg.init[]

// Error mode - write failed updates to separate TP log
if[.stplg.errmode;
  .stplg.openlogerr[.stplg.dldir];
  .stp.upd:.u.upd;
  .u.upd:{[t;x] .[.stp.upd;(t;x);{.stplg.badmsg[x;y;z]}[;t;x]]}
 ]


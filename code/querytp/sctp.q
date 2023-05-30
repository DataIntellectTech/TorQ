\d .sctp

chainedtp:@[value;`chainedtp;0b];                    // switches between STP and SCTP codebase
loggingmode:@[value;`loggingmode;`none];             // [none|create|parent] determines whether SCTP creates its own logs, uses STP logs or does neither
tickerplantname:@[value;`tickerplantname;`stp1];     // tickerplant name to try and make a connection to  
tpconnsleep:@[value;`tpconnsleep;10];                // number of seconds between attempts to connect to source tickerplant
tpcheckcycles:@[value;`tpcheckcycles;0W];            // number of times the process will check for an available tickerplant
subscribeto:@[value;`subscribeto;`];                 // list of tables to subscribe for
subscribesyms:@[value;`subscribesyms;`];             // list of syms to subscription to
replay:@[value;`replay;0b];                          // replay the tickerplant log file
schema:@[value;`schema;1b];                          // retrieve schema from tickerplant

// subscribe to segmented tickerplant
subscribe:{[]
  s:.sub.getsubscriptionhandles[`;tickerplantname;()!()];
  if[count s;
      subproc:first s;
      `.sctp.tph set subproc`w;
      // get tickerplant date - default to today's date
      .lg.o[`subscribe;"subscribing to ", string subproc`procname];
      r:.sub.subscribe[subscribeto;subscribesyms;schema;replay;subproc];
      if[`d in key r;.u.d::r[`d]];
      if[(`icounts in key r) & (loggingmode<>`create); // dict r contains icounts & not using own logfile
        subtabs:$[subscribeto~`;key r`icounts;subscribeto],();
        .u.jcounts::.u.icounts::$[0=count r`icounts;()!();subtabs!enlist [r`icounts]subtabs];
      ]
    ];
  }

// Initialise chained STP
init:{
  // Load in timer and subscription code and set top-level end of day/period functions
  .proc.loadf[getenv[`KDBCODE],"/common/timer.q"];
  .proc.loadf[getenv[`KDBCODE],"/common/subscriptions.q"];
  `endofperiod set {[x;y;z] .stplg.endofperiod[x;y;z]};
  `endofday set {[x;y] .stplg.endofday[x;y]};

  // Initialise connections and subscribe to main STP
  .servers.startupdepnamecycles[.sctp.tickerplantname;.sctp.tpconnsleep;.sctp.tpcheckcycles];
  .sctp.subscribe[];
 };

\d .

// Make the SCTP die if the main STP dies
.z.pc:{[f;x] 
  @[f;x;()];
  if[.sctp.chainedtp;
    if[.sctp.tph=x; .lg.e[`.z.pc;"lost connection to tickerplant : ",string .sctp.tickerplantname];exit 1]
    ]
  } @[value;`.z.pc;{{}}];

// Extract data from incoming table as a list
upd:{[t;x]
  x:value flip x;
  .u.upd[t;x]
 }
/ Chained tickerplant 

\d .ctp

/- user defined variables
tickerplantname:@[value;`tickerplantname;`tickerplant1];        /- list of tickerplant names to try and make a connection to
pubinterval:@[value;`pubinterval;0D00:00:00];                   /- publish batch updates at this interval
tpconnsleep:@[value;`tpconnsleep;10];                           /- number of seconds between attempts to connect to the source tickerplant   
createlogfile:@[value;`createlogfile;0b];                       /- create a log file
logdir:@[value;`logdir;`:tplogs];                     		/- hdb directory containing tp logs 
subscribeto:@[value;`subscribeto;`];                            /- list of tables to subscribe for
subscribesyms:@[value;`subscribesyms;`];                        /- list of syms to subscription to
replay:@[value;`replay;0b];                                     /- replay the tickerplant log file
schema:@[value;`schema;1b];                                     /- retrieve schema from tickerplant
clearlogonsubscription:@[value;`clearlogonsubscription;0b];	/- clear logfile on subscription


tph:0N;								/- setting tickerplant handle to null
.u.icounts:.u.jcounts:(`symbol$())!0#0,();    /- initialise icounts & jcounts dict
.u.i:.u.j:0;			
/- clears log
clearlog:{[lgfile]
  if[not type key lgfile;:()];
  .lg.o[`clearlog;"clearing log file : ",string lgfile];
  .[set;(lgfile;());{.lg.e[`clearlog;"cannot empty tickerplant log: ", x]}]
  }

/- open handle to log file
openlog:{[lgfile]
  lgfileexists:type key lgfile;
  /- check if log file is present on disk
  .lg.o[`openlog;
    $[lgfileexists;
      "opening log file : ";
      "creating new log file : "],string lgfile];
  /- create log file
  if[not lgfileexists;
    .[set;(lgfile;());{[lgf;err] .lg.e[`openlog;"cannot create new log file : ",string[lgf]," : ", err]}[lgfile]]];

  /- backup upd & redefine for counting
  updold:`. `upd;
  @[`.;`upd;:;{[t;x] .u.icounts[t]+:count x;}];
  /- set pub and log count
  .u.i:.u.j:@[-11!;lgfile;-11!(-2;lgfile)];
  /- restore upd
  @[`.;`upd;:;updold];

  /- check if log file is corrupt 
  if[0<=type .u.i;
    .lg.e[`openlog;"log file : ",(string lgfile)," is corrupt. Please remove and restart."]];

  /- open handle to logfile
  hopen lgfile
  }

/- subscribe to tickerplant and refresh tickerplant settings
subscribe:{[]
  s:.sub.getsubscriptionhandles[`;.ctp.tickerplantname;()!()];
  if[count s;
      subproc:first s;
      .ctp.tph:subproc`w;
      /- get tickerplant date - default to today's date
      refreshtp @[tph;".u.d";.z.D];
      .lg.o[`subscribe;"subscribing to ", string subproc`procname];
      r:.sub.subscribe[subscribeto;subscribesyms;schema;replay;subproc];
      if[`d in key r;.u.d::r[`d]]; 
      if[(`icounts in key r) & (not createlogfile); /- dict r contains icounts & not using own logfile
	subtabs:$[subscribeto~`;key r`icounts;subscribeto],();
	.u.jcounts::.u.icounts::$[0=count r`icounts;()!();subtabs!enlist [r`icounts]subtabs];
      ]
    ];
  }

/- write to tickerplant log
writetolog:{[t;x]
   /- if x is not a table, make it a table
   if[not 98h=type x;x:flip cols[value t]!(),/:x];
  .u.l enlist (`upd;t;x);
  .u.j+:1;
  }

/- tick by tick publish
tickpub:{[t;x]
  .ps.publish[t;x];
  .u.i:.u.j;
  .u.icounts[t]+:count x;
  }

/- batch publish
batchpub:{[t;x]
  insert[t;x];
  .u.jcounts[t]+:count x;
  }

/- publish to subscribers
publishalltables:{[]
  pubtables:$[any null .ctp.subscribeto;tables[`.];.ctp.subscribeto],();
  .ps.publish'[pubtables;value each pubtables];
  cleartables[pubtables];
  /- update .u.i with .u.j
  .u.i:.u.j;
  .u.icounts:.u.jcounts;
  }

/- dictionary containing tablename!schema
tableschemas:()!()

/- clear each table and reapply attributes
cleartables:{[t]
  /- restore default table schemas, removes data.
  @[`.;t;:;tableschemas t];
  }

/- create tickerplant log file name
createlogfilename:{[d]
  ` sv (.ctp.logdir;`$string[.proc.procname],"_",string d)
  }

/- called at end of day to refresh tickerplant settings
refreshtp:{[d]
  /- close .u.l if opened
  if[@[value;`.u.l;0]; @[hclose;.u.l;()]];
  /- reset log and publish count
  .u.i:.u.j:0;
  .u.icounts::.u.jcounts::(`symbol$())!0#0,();
  /- create log file if required
  if[createlogfile;
    .u.L:createlogfilename[d];
    if[clearlogonsubscription;clearlog .u.L];
  ];
  /- log file handle
  .u.l:$[createlogfile;openlog .u.L;1i];
  /- set date
  .u.d:d;
  }

/- initialises chained tickerplant
initialise:{
  /- connect to parent tickerplant process
  .servers.startup[];
  /- subscribe to the tickerplant
  .ctp.subscribe[]; 
  /- add subscribed table schemas to .ctp.tableschemas, used in cleartables
  if[not notpconnected[]; 
    .ctp.tableschemas:{x!(0#)@'value@'x} (),$[any null .ctp.subscribeto;tables[`.];.ctp.subscribeto]]
  }

/- returns true if tickerplant is not connected
notpconnected:{[]
  0 = count select from .sub.SUBSCRIPTIONS where procname in .ctp.tickerplantname, active}

/- redefine .z.pc to detect loss of tickerplant connection
.z.pc:{[x;y]  
  if[.ctp.tph=y;
    .lg.e[`.z.pc;"lost connection to tickerplant : ",string .ctp.tickerplantname];exit 0];
  x@y
  }[@[value;`.z.pc;{{;}}]] 

/- define upd based on user settings
upd:$[createlogfile;
      $[pubinterval;{[t;x] writetolog[t;x];batchpub[t;x];};{[t;x] writetolog[t;x];tickpub[t;x];}];
      $[pubinterval;batchpub;tickpub]];

/- ctp sub method, returns logfile, i and icounts as well as schema
sub:{[subtabs;subsyms]
  r:(`schema`icounts`i`logfile`d)!();
  /- get schema & subscribe
  r[`schema]:.u.sub[subtabs;subsyms];
  /- add icounts if subscribing to all syms
  if[subscribesyms~`;r[`icounts]:.u.icounts];
  /- if logfile, add logfile & i
  if[createlogfile;r[`i]:.u.i;r[`logfile]:.u.L];
  /- add date
  r[`d]:.u.d;
  r
  }

\d .u

/- publishes all tables then clears them, pass on .u.end to subscribers
end:{[d]
  .lg.o[`end;"end of day invoked"];
  /- publish and clear all the tables 
  .ctp.publishalltables[];
  /- roll over the log you need a new log for next days data 
  .ctp.refreshtp[d+1];
  /- push endofday messages to subscribers
  (neg union/[w[;;0]])@\:(`.u.end;d)
  }

\d .

/- set upd function in the top level name space, provided it isn't already defined
if[not `upd in key `.; upd:.ctp.upd];

/- pubsub must be initialised sooner to enable tickerplant replay publishing to work
.ps.initialise[];                                                                   

/- check if the tickerplant has connected, blocks the process until a connection is established
.ctp.initialise[];
while[.ctp.notpconnected[];
  /- while not connected make the process sleep for X seconds and then run the subscribe function again
  .os.sleep[.ctp.tpconnsleep];
  /- start chained tickerplant
  .ctp.initialise[]];

/- set timer for batch update publishing
if[.ctp.pubinterval;
  .timer.rep[.proc.cp[];0Wp;.ctp.pubinterval;(`.ctp.publishalltables;`);1h;"Publishes batch updates to subscribers";1b]];

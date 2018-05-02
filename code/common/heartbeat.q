// Heartbeating
// All processes can publish heartbeats.  This allows downstream processes to check they are available and not blocked
// If if the connection is still valid the process may be unavailable
// This script handles both publishing of heartbeats, and functions for checking if the required heartbeats are received in a timely manner
// The pubsub is reliant on a pubsub implementation e.g. u.[q|k]

// Override the processwarning and processerror functions to implement required behaviour when warnings or errors are encountered
// Override warningperiod and errorperiod functions to have bespoke warning and error periods for different process types
// Use storeheartbeat function in the upd function to process heartbeats

\d .hb

enabled:@[value;`enabled;1b]					// whether the heartbeating is enabled
subenabled:@[value;`subenabled;0b]                              // whether subcriptions to heartbeats are enabled
debug:@[value;`debug;1b]					// whether to print debug information
publishinterval:@[value;`publishinterval;0D00:00:30]		// how often heartbeats are published
checkinterval:@[value;`checkinterval;0D00:00:10]		// how often heartbeats are checked
warningtolerance:@[value;`warningtolerance;1.5f]		// a process will move to warning state when it hasn't heartbeated in warningtolerance*checkinterval
errortolerance:@[value;`errortolerance;2f]			// and to an error state when it hasn't heartbeated in errortolerance*checkinterval
CONNECTIONS:@[value;`CONNECTIONS;()];                           // processes that heartbeat subscriptions are recieved from (as a subset of .servers.CONNECTIONS)
subscribedhandles:0 0Ni

// table for publishing heartbeats
// sym = proctype
heartbeat:([]time:`timestamp$(); sym:`symbol$(); procname:`symbol$(); counter:`long$(); pid:`int$(); host:`$(); port:`int$())

// process ID, hostname and port
pid:.z.i
host:.z.h
port:system"p"

// create a keyed version of the heartbeat table to store the incoming heartbeats
hb:update warning:0b, error:0b from `sym`procname xkey heartbeat

// functions to get the warning and error tolerances
// to have different warnings or errors for different process types, modify these functions
warningperiod:{[processtype] `timespan$warningtolerance*publishinterval}
errorperiod:{[processtype] `timespan$errortolerance*publishinterval}

// heartbeat counter
hbcounter:@[value;`hbcounter;0j]

// publish a heartbeat
publishheartbeat:{
 if[@[value;`.ps.initialised;0b];
  .ps.publish[`heartbeat;enlist `time`sym`procname`counter`pid`host`port!(.proc.cp[];.proc.proctype;.proc.procname;hbcounter;pid;host;port)];
  hbcounter+::1]}

// add a set of process names and types to seed the heartbeat table
addprocs:{[proctypes;procnames] .hb.hb:(2!([]sym:proctypes,();procname:procnames,();time:.proc.cp[];counter:0Nj;pid:0Nj;host:`;port:0Nj;warning:0b;error:0b)),.hb.hb}

// store an incoming heartbeat
storeheartbeat:{[hb]
 // store the heartbeat
 `.hb.hb upsert update warning:0b,error:0b from select by sym,procname from hb};

// check if any of the heartbeats are in error or warning
checkheartbeat:{
 now:.proc.cp[];
 // calculate which processes haven't heartbeated recently enough
 stats:update status+`short$2*now>time+.hb.errorperiod[sym] from
   update status:`short$now>time+.hb.warningperiod[sym] from .hb.hb;
 warn[select from stats where status=1,not warning];
 err[select from stats where status>1,not error];
 }

// process warnings and errors
warn:{
 if[debug;
  {.lg.o[`heartbeat;"processtype ",(string x`sym),", processname ",(string x`procname)," has not heartbeated since ",(string x`time)," and has status WARNING"]} each 0!x];
 update warning:1b from `.hb.hb where ([]sym;procname) in key x;
 processwarning[x]}

err:{
 if[debug;
  {.lg.e[`heartbeat;"processtype ",(string x`sym),", processname ",(string x`procname)," has not heartbeated since ",(string x`time)," and has status ERROR"]} each 0!x];
 update error:1b from `.hb.hb where ([]sym;procname) in key x;
 // key x is .hb.hb table with an extra status column
 // It is empty most of the time but will contain a row if the process has not heartbeat
 processerror[x]}

// override these functions to implement bespoke functionality on heartbeat errors and warnings
processwarning:{[processtab]
  if[1<=count processtab;
     .html.pub[`heartbeat;0!select from .hb.hb where procname in exec procname from processtab]]}

processerror:{[processtab]
  if[1<=count processtab;
     .html.pub[`heartbeat;0!select from .hb.hb where procname in exec procname from processtab]]}

// subscribe to heartbeats and log messages on a handle
subscribe:{[handle]
 @[{x(`.ps.subscribe;`heartbeat;`); subscribedhandles,::x};handle;{.lg.e[`hbsub;"failed to subscribe to heartbeat on handle ",(string x),": ",y]}[handle]];
 }

hbsubscriptions:{[]
  getheartbeats .hb.CONNECTIONS
 }

getheartbeats:{[proctype]
  if[`ALL in proctype; proctype:`];
  // only get handles that have not been subscribed to
  handles:(.servers.getservers[`proctype;proctype;()!();0b;0b]`w) except subscribedhandles;
  if[count handles;
    .lg.o[`hbsub;"subscribing to new handle(s) ",", " sv string handles];
    subscribe each handles]
 }

\d .

// set the heartbeat table to the top level namespace, to allow it to be initialised in the pub/sub routine
heartbeat:.hb.heartbeat;
if[(not @[value;`.proc.lowpowermode;0b]) & @[value;`enabled;1b];
 // add the checkheartbeat function to the timer
 $[@[value;`.timer.enabled;0b] and `publish in key `.ps;
  [.lg.o[`init;"adding heartbeat functions to the timer"];
   .timer.repeat[.proc.cp[];0Wp;.hb.publishinterval;(`.hb.publishheartbeat;`);"publish heartbeats"];
   .timer.repeat[.proc.cp[];0Wp;.hb.checkinterval;(`.hb.checkheartbeat;`);"check the heartbeats have been received in a timely manner"]];
  .lg.e[`init;"heartbeating is enabled, but the timer and/or pubsub code is not enabled"]]];

if[.hb.subenabled;
  upd:{[f;t;x] if[t=`heartbeat; .hb.storeheartbeat[x]]; f . (t;x)}@[value;`upd;{{[t;x]}}];

  .z.pc:{if[y;.hb.subscribedhandles::.hb.subscribedhandles except y]; x@y}@[value;`.z.pc;{{[x]}}];

  .timer.rep[.z.p;0wp;0D00:01:00;(`.hb.hbsubscriptions;`);0h;"subscribe to heartbeats";0b];

  .servers.connectcustom:{[func;connectiontab]
    // only return servers specified by .hb.CONNECTIONS
    // if `ALL is specified then all servers are returned
    connectiontab:$[`ALL in .hb.CONNECTIONS;
      connectiontab;
      select from connectiontab where proctype in .hb.CONNECTIONS];
    // only select records with unsubscribed handles
    connectiontab:select from connectiontab where not w in .hb.subscribedhandles;
    // subscribed to new handles
    if[count connectiontab;
      .hb.subscribe each connectiontab`w];
    func@connectiontab
   }@[value;`.servers.connectcustom;{{[x]}}]
 ]

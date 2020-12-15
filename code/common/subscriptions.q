/-script to create subscriptions, e.g. to tickerplant

\d .sub

AUTORECONNECT:@[value;`AUTORECONNECT;1b];									//resubscribe to processes when they come back up
checksubscriptionperiod:(not @[value;`.proc.lowpowermode;0b]) * @[value;`checksubscriptionperiod;0D00:00:10]  	//how frequently you recheck connections.  0D = never

// table of subscriptions
SUBSCRIPTIONS:([]procname:`symbol$();proctype:`symbol$();w:`int$();table:();instruments:();createdtime:`timestamp$();active:`boolean$());

getsubscriptionhandles:{[proctype;procname;attributes]
  // grab data from .serves.SERVERS, add handling for passing in () as an argument
  data:{select procname,proctype,w from x}each .servers.getservers[;;attributes;1b;0b]'[`proctype`procname;(proctype;procname)];
  $[0h in type each (proctype;procname);distinct raze data;inter/[data]]
 }

updatesubscriptions:{[proc;tab;instrs]
  // delete any inactive subscriptions
  delete from `.sub.SUBSCRIPTIONS where not active;
  if[instrs~`;instrs,:()];
  .sub.SUBSCRIPTIONS::0!(4!SUBSCRIPTIONS)upsert enlist proc,`table`instruments`createdtime`active!(tab;instrs;.proc.cp[];1b);
 }

reconnectinit:0b;		//has the reconnect custom function been initialised

reducesubs:{[tabs;utabs;instrs;proc]
  // for a given list of subscription tables, remove any which have already been subscribed to

  // if asking for all tables, subscribe to the full list available from the publisher
  subtabs:$[tabs~`;utabs;tabs],();
  .lg.o[`subscribe;"attempting to subscribe to ",(","sv string subtabs)," on handle ",string proc`w];
 
  // if the process has already been subscribed to
  if[not instrs~`; instrs,:()];
  s:select from SUBSCRIPTIONS where ([]procname;proctype;w)~\:proc, table in subtabs,instruments~\:instrs, active;
  if[count s;
    .lg.o[`subscribe;"already subscribed to specified instruments from  ",(","sv string s`table)," on handle ",string proc`w];
    subtabs:subtabs except s`table];
 
  // if the requested tables aren't available, ignore them and log a message
  if[count errtabs:subtabs except utabs;
    .lg.o[`subscribe;"tables ",("," sv string errtabs)," are not available to be subscribed to, they will be ignored"];
    subtabs:subtabs inter utabs;];
 
  // return a dict of the reduced subscriptions
  :`subtabs`errtabs`instrs!(subtabs;errtabs;instrs)
 } 

createtables:{
  // x is a list of pairs (tablename; schema)
  .lg.o[`subscribe;"setting the schema definition"];
  // this is the same as (tablename set schema)each table subscribed to
  (@[`.;;:;].)each x where not 0=count each x;
 }

replay:{[tabs;realsubs;schemalist;logfilelist]
  // realsubs is a dict of `subtabs`errtabs`instrs
  // schemalist is a list of (tablename;schema)
  // logfilelist is a list of (log count; logfile) 
  .lg.o[`subscribe;"replaying the log file(s)"];
  // store the orig version of upd
  origupd:@[value;`..upd;{{[x;y]}}];
  // only use tables user has access to
  subtabs:realsubs[`subtabs];
  if[count where nullschema:0=count each schemalist;
    tabs:(schemalist where not nullschema)[;0];
    subtabs:tabs inter realsubs[`subtabs]];
  // set the replayupd function to be upd globally
  if[not (tabs;realsubs[`instrs])~(`;`);
    .lg.o[`subscribe;"using the .sub.replayupd function as not replaying all tables or instruments"];
    @[`.;`upd;:;.sub.replayupd[origupd;subtabs;realsubs[`instrs]]]];
  {[d] @[{.lg.o[`subscribe;"replaying log file ",.Q.s1 x]; -11!x;};d;{.lg.e[`subscribe;"could not replay the log file: ", x]}]}each logfilelist;
  // reset the upd function back to original upd
  @[`.;`upd;:;origupd];
  .lg.o[`subscribe;"finished log file replay"];
  // return updated version of realsubs
  @[realsubs;`subtabs;:;subtabs]
 }

subscribe:{[tabs;instrs;setschema;replaylog;proc]
  // if proc dictionary is empty then exit - no connection
  if[0=count proc;.lg.o[`subscribe;"no connections made"]; :()];

  // check required flags are set, and add a definintion to the reconnection logic
  // when the process is notified of a new connection, it will try and resubscribe
  if[(not .sub.reconnectinit)&.sub.AUTORECONNECT;
    $[.servers.enabled;
      [.servers.connectcustom:{x@y;.sub.autoreconnect[y]}[.servers.connectcustom]; .sub.reconnectinit:1b];
      .lg.o[`subscribe;"autoreconnect was set to true but server functionality is disabled - unable to use autoreconnect"]];
   ];
 
  // work out from the remote connection what type of tickerplant we are subscribing to
  // default to `standard
  tptype:@[proc`w;({@[value;`tptype;`standard]};`);`];
  if[null tptype; .lg.e[`subscribe;e:"could not determine tickerplant type"]; 'e];
 
  // depending on the type of tickerplant being subscribed to, change the functions for requesting
  // the tables and subscriptions
  $[tptype=`standard;
    [tablesfunc:{key `.u.w};
      subfunc:{`schemalist`logfilelist`rowcounts`date!(.u.sub\:[x;y];enlist(.u`i`L);(.u `icounts);(.u `d))}];
    tptype=`segmented;
    [tablesfunc:`tablelist;
      subfunc:`subdetails];
    [.lg.e[`subscribe;e:"unrecognised tickerplant type: ",string tptype]; 'e]];
 
  // pull out the full list of tables to subscribe to
  utabs:@[proc`w;(tablesfunc;`);()];
  // reduce down the subscription list
  realsubs:reducesubs[tabs;utabs;instrs;proc];
  // check if anything to subscribe to, and jump out
  if[0=count realsubs`subtabs;
    .lg.o[`subscribe;"all tables have already been subscribed to"];
    :()];

  // pull out subscription details from the TP
  details:@[proc`w;(subfunc;realsubs[`subtabs];realsubs[`instrs]);{.lg.e[`subscribe;"subscribe failed : ",x];()}];
  if[count details;
    if[setschema;createtables[details[`schemalist]]];
    if[replaylog;realsubs:replay[tabs;realsubs;details[`schemalist];details[`logfilelist]]];
    .lg.o[`subscribe;"subscription successful"];
    updatesubscriptions[proc;;realsubs[`instrs]]each realsubs[`subtabs]];

  // return the names of the tables that have been subscribed for and
  // the date from the name of the tickerplant log file (assuming the tp log has a name like `: sym2014.01.01
  // plus .u.i and .u.icounts if existing on TP - details[1;0] is .u.i, details[2] is .u.icounts (or null)
  logdate:0Nd;
  if[tptype=`standard;
    d:(`subtables`tplogdate!(details[`schemalist][;0];(first "D" $ -10 sublist string last first details[`logfilelist])^logdate));
    :d,{(where 101 = type each x)_x}(`i`icounts`d)!(details[`logfilelist][0;0];details[`rowcounts];details[`date])];
  if[tptype~`segmented;
    retdic:`logdir`subtables!(details[`logdir];details[`schemalist][;0]);
    :retdic,{(where 101 = type each x)_x}`i`icounts`d`tplogdate!details[`logfilelist`rowcounts`date`date];
    ]
 }

// wrapper function around upd which is used to only replay syms and tables from the log file that
// the subscriber has requested
replayupd:{[f;tabs;syms;t;x]
  // escape if the table is not one of the subscription tables
  if[not (t in tabs) or tabs ~ `;:()];
  // if subscribing for all syms then call upd and then escape
  if[(syms ~ `)or 99=type syms; f[t;x];:()];
  // filter down on syms
  // assuming the the log is storing messages (x) as arrays as opposed to tables
  c:cols[`. t];
  // convert x into a table
  x:select from $[type[x] in 98 99h; x; 0>type first x;enlist c!x;flip c!x] where sym in syms;
  // call upd on the data
  f[t;x]
 }

checksubscriptions:{update active:0b from `.sub.SUBSCRIPTIONS where not w in key .z.W;}

retrysubscription:{[row]
  subscribe[row`table;$[((),`) ~ insts:row`instruments;`;insts];0b;0b;3#row];
 }

// if something becomes available again try to reconnect to any previously subscribed tables/instruments
autoreconnect:{[rows]
  s:select from SUBSCRIPTIONS where ([]procname;proctype)in (select procname, proctype from rows), not active;
  s:s lj 2!select procname,proctype,w from rows;
  if[count s;.sub.retrysubscription each s];
 }

pc:{[result;W] update active:0b from `.sub.SUBSCRIPTIONS where w=W;result}
// set .z.pc handler to update the subscriptions table
.z.pc:{.sub.pc[x y;y]}@[value;`.z.pc;{[x]}];

// if timer is set, trigger reconnections
$[.timer.enabled and checksubscriptionperiod > 0;
    .timer.rep[.proc.cp[];0Wp;checksubscriptionperiod;(`.sub.checksubscriptions`);0h;"check all subscriptions are still active";1b];
  checksubscriptionperiod > 0;
    .lg.e[`subscribe;"checksubscriptionperiod is set but timer is not enabled"];
  ()]

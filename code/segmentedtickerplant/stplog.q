// Utilites for periodic tp logging in stp process

// Live logs and handles to logs for each table
currlog:([tbl:`symbol$()]logname:`symbol$();handle:`int$())

// View of log file handles for faster lookups
loghandles::exec tbl!handle from currlog

\d .stplg

// Create stp log directory
// Log structure `:stplogs/date/tabname_time
createdld:{[name;date]
  $[count dir:getenv[`KDBSTPLOG];
    [.os.md dir;.os.md dldir::hsym`$raze dir,"/",string name,date];
    [.lg.e[`stp;"log directory not defined"];exit]
  ]
 };

// Functions to generate log names in one of five modes ///////////////////////////////

logname:enlist[`]!enlist ()

// Default stp mode is tabperiod
// TP log rolled periodically (default 1 hr), 1 log per table
logname[`tabperiod]:{[dir;tab;p]
   ` sv(hsym dir;`$string[tab],raze[string"du"$p]except".:")
 };

// Standard TP mode - write all tables to single log, roll daily
logname[`none]:{[dir;tab;p]
  ` sv(hsym .stplg.dldir;`$string[.proc.procname],"_",string[.z.d]except".")
 };

// Periodic-only mode - write all tables to single log, roll periodically intraday
logname[`periodic]:{[dir;tab;p]
  ` sv(hsym dir;`$"periodic",raze[string"du"$p]except".:")
 };

// Tabular-only mode - write tables to separate logs, roll daily
logname[`tabular]:{[dir;tab;p]
  ` sv(hsym dir;`$string[tab],"_",string[.z.d]except".")
 };

// Custom mode - mixed periodic/tabular mode
// Tables are defined as periodic, tabular, tabperiod or none in config file stpcustom.csv
// Tables not specified in csv are not logged
logname[`custom]:{[dir;tab;p]
  logname[custommode tab][dir;tab;p]
 };

///////////////////////////////////////////////////////////////////////////////////////

// Update and timer functions in three batch modes ////////////////////////////////////

upd:zts:enlist[`]!enlist ()

// If set to autobatch, publish and write to disk will be run in batches
upd[`autobatch]:{[t;x]
  .stpps.upd[t;x];
 };

zts[`autobatch]:{
  {[t;x] .stpps.pub[t;x];
  `..loghandles[t] enlist(`upd;t;x)}'[.stpps.t;value each .stpps.t];
  @[`.;.stpps.t;@[;`sym;`g#]0#];
  ts .z.p;
 };

// Standard batch mode - publish in batches, write to disk immediately
upd[`defaultbatch]:{[t;x]
  x:.stpps.upd[t;x];
  `..loghandles[t] enlist(`upd;t;x);
 };

zts[`defaultbatch]:{
  .stpps.pub'[.stpps.t;value each .stpps.t];
  @[`.;.stpps.t;@[;`sym;`g#]0#];
  ts .z.p;
 };

// Immediate mode - publish and write immediately
upd[`immediate]:{[t;x]
  x:.stpps.updtab[t]@x;
  `..loghandles[t] enlist(`upd;t;x);
  .stpps.pub[t;x]
 };

zts[`immediate]:{ts .z.p}

//////////////////////////////////////////////////////////////////////////////////////

// Number of update messages received for each table
msgcount:enlist[`]!enlist ()

// Total messages received
totalmsgcount:0Ni

// Open log for a single table at start of logging period
openlog:{[multilog;dir;tab;p]
  lname:logname[multilog][dir;tab;p];
  h:$[not type key lname;
    [.[lname;();:;()];hopen lname];
    exec first handle from `..currlog where logname=lname
  ];
  `..currlog upsert (tab;lname;h);
 };

// Error log for failed updates in error mode
openlogerr:{[dir]
  lname:` sv(hsym dir;`$"errdatabase_",string[.eodtime.d]except".");
  if[not type key lname;.[lname;();:;()]];
  h:hopen lname;
  `..currlog upsert (`err;lname;h);
 };

// Log failed message and error type in error mode
badmsg:{[e;t;x]
  .lg.o[`upd;"Bad message received, error: ",e];
  `..loghandles[`err] enlist(`upderr;t;x);
 };

closelog:{[tab]
  if[null h:`..currlog[tab;`handle];.lg.o[`closelog;"No open handle to log file"];:()];
  @[hclose;h;.lg.e[`closelog;"Handle already closed"]];
  update handle:0N from `..currlog where tbl=tab;
 };

// Roll all logs at end of logging period
rolllog:{[multilog;dir;tabs]
  .stpm.updmeta[multilog][`close;tabs;.z.p];
  closelog each tabs;
  i+::1;
  @[`.stplg.msgcount;tabs;:;0];
  openlog[multilog;dir;;.eodtime.currperiod]each tabs;
  .stpm.updmeta[multilog][`open;tabs;.z.p];
 };

// Send close of period message to subscribers, update logging period times, roll logs
endofperiod:{
  .stpps.endp . .eodtime`p`nextperiod;
  .eodtime.currperiod:.eodtime.nextperiod;
  if[.z.p>.eodtime.nextperiod:.eodtime.getperiod[.z.p;multilogperiod;.eodtime.currperiod];
    system"t 0";'"next period is in the past"];
  rolllog[multilog;dldir;rolltabs];
 };

endofday:{
  .stpps.end d;
  if[.z.p>.eodtime.nextroll:.eodtime.getroll[.z.p];system"t 0";'"next roll is in the past"];
  .stpm.updmeta[multilog][`close;logtabs;.z.p];
  closelog each logtabs;
  .eodtime.d+::1;
  init[];
 };

ts:{
  if[.eodtime.nextperiod < x; endofperiod[]];
  if[.eodtime.nextroll < x;if[d<("d"$x)-1;system"t 0";'"more than one day?"];endofday[]];
 };

init:{
  t::tables[`.]except `currlog;
  i::0;
  @[`.stplg.msgcount;t;:;0];
  totalmsgcount::0;
  logtabs::$[multilog~`custom;key custommode;t];
  rolltabs::$[multilog~`custom;logtabs except where custommode in `tabular`none;t];
  .eodtime.currperiod:multilogperiod xbar .z.p;
  .eodtime.nextperiod:.eodtime.getperiod[.z.p;multilogperiod;.eodtime.currperiod];
  createdld[`database;.eodtime.d];
  openlog[multilog;dldir;;.z.p]each logtabs;
  .stpm.updmeta[multilog][`open;logtabs;.z.p];
 };

\d .


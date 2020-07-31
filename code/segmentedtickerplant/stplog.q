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

upd:zts:batch:enlist[`]!enlist ()

// If set to autobatch, publish and write to disk will be run in batches
upd[`autobatch]:{[t;x]
  x:.stpps.updtab[t]@x;
  @[`.stplg.batch;t;,;enlist (`upd;t;x)]
 };

zts[`autobatch]:{
  {[t]
    x:batch[t];
    if[count x;
      .stpps.pub[t;x];
      `..loghandles[t] x]
  }each .stpps.t;
  batch::.stpps.t!();
  ts .z.p+.eodtime.dailyadj;
 };

// Standard batch mode - publish in batches, write to disk immediately
upd[`defaultbatch]:{[t;x]
  x:.stpps.upd[t;x];
  `..loghandles[t] enlist(`upd;t;x);
 };

zts[`defaultbatch]:{
  .stpps.pub'[.stpps.t;value each .stpps.t];
  @[`.;.stpps.t;:;.stpps.schemas[.stpps.t]];
  ts .z.p+.eodtime.dailyadj;
 };

// Immediate mode - publish and write immediately
upd[`immediate]:{[t;x]
  x:.stpps.updtab[t]@x;
  `..loghandles[t] enlist(`upd;t;x);
  .stpps.pub[t;x]
 };

zts[`immediate]:{ts .z.p+.eodtime.dailyadj}

//////////////////////////////////////////////////////////////////////////////////////

// Number of update messages received for each table
msgcount:enlist[`]!enlist ()

// Total messages received
totalmsgcount:0Ni

// Functions to obtain logs for client replay ////////////////////////////////////////
// replaylog called from client-side, returns nested list of logcounts and lognames
replaylog:{[t]
  getlogs[replayperiod][t]
 }

getlogs:enlist[`]!enlist ()

// If replayperiod set to `period, only replay logs for current logging period
getlogs[`period]:{[t]
  distinct flip (.stplg.msgcount;exec tbl!logname from `..currlog where tbl in t)@\:t
 };

// If replayperiod set to `day, replay all of today's logs
getlogs[`day]:{[t]
  lnames:distinct uj/[{
    select seq,tbls,logname,msgcount from .stpm.metatable where x in/: tbls
    }each t];
  // Meta table does not store counts for live logs, so these are populated here
  lnames:update msgcount:sum each .stplg.msgcount[tbls] from lnames where seq=.stplg.i;
  flip value exec `long$msgcount,logname from lnames
 };

//////////////////////////////////////////////////////////////////////////////////////

// Open log for a single table at start of logging period
openlog:{[multilog;dir;tab;p]
  lname:logname[multilog][dir;tab;p];
  h:$[(not type key lname)or null h0:exec first handle from `..currlog where logname=lname;
    [.[lname;();:;()];hopen lname];
    h0
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
rolllog:{[multilog;dir;tabs;p]
  .stpm.updmeta[multilog][`close;tabs;p];
  closelog each tabs;
  @[`.stplg.msgcount;tabs;:;0];
  {[m;d;t]
    .[openlog;(m;d;t;.eodtime.currperiod);
      {.lg.e[`stp;"failed to open log for table ",string[y]]}[;t]]
  }[multilog;dir;]each tabs;
  .stpm.updmeta[multilog][`open;tabs;p];
 };

// Send close of period message to subscribers, update logging period times, roll logs
endofperiod:{[p]
  .stpps.endp . .eodtime`p`nextperiod;
  .eodtime.currperiod:.eodtime.nextperiod;
  if[p>.eodtime.nextperiod:.eodtime.getperiod[multilogperiod;.eodtime.currperiod];
    system"t 0";'"next period is in the past"];
  i+::1;
  rolllog[multilog;dldir;rolltabs;p];
  totalmsgcount::0;
 };

endofday:{[p]
  .stpps.end .eodtime.d;
  if[p>.eodtime.nextroll:.eodtime.getroll[p];system"t 0";'"next roll is in the past"];
  .stpm.updmeta[multilog][`close;logtabs;p];
  .stpm.metatable:0#.stpm.metatable;
  closelog each logtabs;
  .eodtime.d+:1;
  init[];
 };

ts:{
  if[.eodtime.nextperiod < x; endofperiod[x]];
  if[.eodtime.nextroll < x;if[.eodtime.d<("d"$x)-1;system"t 0";'"more than one day?"];endofday[x]];
 };

init:{
  t::tables[`.]except `currlog;
  i::0;
  @[`.stplg.msgcount;t;:;0];
  totalmsgcount::0;
  batch::t!();
  logtabs::$[multilog~`custom;key custommode;t];
  rolltabs::$[multilog~`custom;logtabs except where custommode in `tabular`none;t];
  .eodtime.currperiod:multilogperiod xbar .z.p+.eodtime.dailyadj;
  .eodtime.nextperiod:.eodtime.getperiod[multilogperiod;.eodtime.currperiod];
  createdld[`database;.eodtime.d];
  openlog[multilog;dldir;;.z.p+.eodtime.dailyadj]each logtabs;
  .stpm.updmeta[multilog][`open;logtabs;.z.p+.eodtime.dailyadj];
 };

\d .


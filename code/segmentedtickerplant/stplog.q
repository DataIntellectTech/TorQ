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

logname:@[value;`.stplg.logname;enlist[`]!enlist ()];

// Default stp mode is tabperiod
// TP log rolled periodically (default 1 hr), 1 log per table
logname[`tabperiod]:{[dir;tab;p]
  ` sv(hsym dir;`$string[tab],raze[string"dv"$p]except".:")
 };

// Standard TP mode - write all tables to single log, roll daily
logname[`none]:{[dir;tab;p]
  ` sv(hsym .stplg.dldir;`$string[.proc.procname],"_",string[.z.d]except".")
 };

// Periodic-only mode - write all tables to single log, roll periodically intraday
logname[`periodic]:{[dir;tab;p]
  ` sv(hsym dir;`$"periodic",raze[string"dv"$p]except".:")
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
// preserve pre-existing definitions
upd:@[value;`.stplg.upd;enlist[`]!enlist ()];
zts:@[value;`.stplg.zts;enlist[`]!enlist ()];

// Number of update messages received for each table
msgcount:rowcount:tmpmsgcount:tmprowcount:enlist[`]!enlist ()

// Sequence number
seqnum:0

// Functions to add columns on updates
updtab:@[value;`.stplg.updtab;enlist[`]!enlist {(enlist(count first x)#y),x}]

// If set to autobatch, publish and write to disk will be run in batches
// insert to table in memory, on a timer flush the table to disk and publish, update counts
upd[`autobatch]:{[t;x;now]
  t insert updtab[t] . (x;now);
 };

zts[`autobatch]:{
  {[t]
    if[count value t;
      `..loghandles[t] enlist (`upd;t;value flip value t);
      @[`.stplg.msgcount;t;+;1];
      @[`.stplg.rowcount;t;+;count value t];
      .stpps.pubclear[t]];
  }each .stpps.t;
 };

// Standard batch mode - write to disk immediately, publish in batches
upd[`defaultbatch]:{[t;x;now]
  t insert x:.stplg.updtab[t] . (x;now);
  `..loghandles[t] enlist(`upd;t;x);
  // track tmp counts, and add these after publish
  @[`.stplg.tmpmsgcount;t;+;1];
  @[`.stplg.tmprowcount;t;+;count first x];
 };

zts[`defaultbatch]:{
  // publish and clear all tables, increment counts
  .stpps.pubclear[.stpps.t];
  // after data has been published, updated the counts
  .stplg.msgcount+:.stplg.tmpmsgcount;
  .stplg.rowcount+:.stplg.tmprowcount;
  // reset temp counts
  .stplg.tmpmsgcount:.stplg.tmprowcount:()!();
 };

// Immediate mode - publish and write immediately
upd[`immediate]:{[t;x;now]
  x:updtab[t] . (x;now);
  `..loghandles[t] enlist(`upd;t;x);
  @[`.stplg.msgcount;t;+;1];
  @[`.stplg.rowcount;t;+;count first x];
  .stpps.pub[t;x]
 };

zts[`immediate]:{}

//////////////////////////////////////////////////////////////////////////////////////

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
  h:$[(notexists:not type key lname)or null h0:exec first handle from `..currlog where logname=lname;
    [.[if[notexists;lname;();:;()]];hopen lname];
    h0
  ];
  `..currlog upsert (tab;lname;h);
 };

errorlogname:@[value;`.stplg.errorlogname;`err]

// Error log for failed updates in error mode
openlogerr:{[dir]
  lname:` sv(hsym dir;`$string[errorlogname],string[.eodtime.d]except".");
  if[not type key lname;.[lname;();:;()]];
  h:hopen lname;
  `..currlog upsert (errorlogname;lname;h);
 };

// Log failed message and error type in error mode
badmsg:{[e;t;x]
  .lg.o[`upd;"Bad message received, error: ",e];
  `..loghandles[errorlogname] enlist(`upderr;t;x);
 };

closelog:{[tab]
  if[null h:`..currlog[tab;`handle];.lg.o[`closelog;"No open handle to log file"];:()];
  @[hclose;h;{.lg.e[`closelog;"Handle already closed"]}];
  update handle:0N from `..currlog where tbl=tab;
 };

// Roll all logs at end of logging period
rolllog:{[multilog;dir;tabs;p]
  .stpm.updmeta[multilog][`close;tabs;p];
  closelog each tabs;
  @[`.stplg.msgcount;tabs;:;0];
  {[m;d;t]
    .[openlog;(m;d;t;.eodtime.currperiod);
      {.lg.e[`stp;"failed to open log for table ",string[y],": ",x]}[;t]]
  }[multilog;dir;]each tabs;
  .stpm.updmeta[multilog][`open;tabs;p];
 };

// Send close of period message to subscribers, update logging period times, roll logs
endofperiod:{[p]
  .stpps.endp . .eodtime`currperiod`nextperiod;
  .eodtime.currperiod:.eodtime.nextperiod;
  if[p>.eodtime.nextperiod:.eodtime.getperiod[multilogperiod;.eodtime.currperiod];
    system"t 0";'"next period is in the past"];
  getnextend[];
  i+::1;
  rolllog[multilog;dldir;rolltabs;p];
 };

// send end of day to subscribers, close out current logs, roll the day, 
// create new and directory for the next day
endofday:{[p]
  .stpps.end .eodtime.d;
  if[p>.eodtime.nextroll:.eodtime.getroll[p];system"t 0";'"next roll is in the past"];
  getnextend[];
  .stpm.updmeta[multilog][`close;logtabs;p];
  .stpm.metatable:0#.stpm.metatable;
  closelog each logtabs;
  .eodtime.d+:1;
  init[`. `dbname];
 };

// get the next end time to compare to
getnextend:{nextend::min(.eodtime.nextroll;.eodtime.nextperiod)}

checkends:{
  // jump out early if don't have to do either 
  if[nextend > x; :()];
  if[.eodtime.nextperiod < x; endofperiod[x]];
  if[.eodtime.nextroll < x;if[.eodtime.d<("d"$x)-1;system"t 0";'"more than one day?"];endofday[x]];
 };

init:{[dbname]
  t::tables[`.]except `currlog;
  @[`.stplg.msgcount;t;:;0];
  logtabs::$[multilog~`custom;key custommode;t];
  rolltabs::$[multilog~`custom;logtabs except where custommode in `tabular`none;t];
  .eodtime.currperiod:multilogperiod xbar .z.p+.eodtime.dailyadj;
  .eodtime.nextperiod:.eodtime.getperiod[multilogperiod;.eodtime.currperiod];
  getnextend[]; 
  createdld[dbname;.eodtime.d];
  openlog[multilog;dldir;;.z.p+.eodtime.dailyadj]each logtabs;
  // read in the meta table from disk 
  .stpm.metatable:@[get;hsym`$string[.stplg.dldir],"/stpmeta";0#.stpm.metatable];
  // set log sequence number to the max of what we've found
  i::1+ -1|exec max seq from .stpm.metatable;
  // add the info to the meta table
  .stpm.updmeta[multilog][`open;logtabs;.z.p+.eodtime.dailyadj];
 };

\d .


// Utilites for periodic tp logging in stp process

// Live logs and handles to logs for each table
currlog:([tbl:`symbol$()]logname:`symbol$();handle:`int$())

// View of log file handles for faster lookups
loghandles::exec tbl!handle from currlog

.stplg.chainedtp:chainedtp;
.stplg.createlogs:createlogs;

\d .stplg

// Create stp log directory
// Log structure `:stplogs/date/tabname_time
createdld:{[name;date]
  $[count dir:$[chainedtp;getenv[`KDBSCTPLOG];getenv[`KDBSTPLOG]];
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
  ` sv(hsym dir;`$string[.proc.procname],"_",raze[string"dv"$p]except".:")
 };

// Periodic-only mode - write all tables to single log, roll periodically intraday
logname[`periodic]:{[dir;tab;p]
  ` sv(hsym dir;`$"periodic",raze[string"dv"$p]except".:")
 };

// Tabular-only mode - write tables to separate logs, roll daily
logname[`tabular]:{[dir;tab;p]
  ` sv(hsym dir;`$string[tab],"_",raze[string"dv"$p]except".:")
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

// If set to memorybatch, publish and write to disk will be run in batches
// insert to table in memory, on a timer flush the table to disk and publish, update counts
upd[`memorybatch]:{[t;x;now]
  // only timestamps if not in CTP mode
  if[not chainedtp; x: updtab[t] . (x;now)];
  t insert x;
 };

zts[`memorybatch]:{
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
  // only timestamps if not in CTP mode
  if[not chainedtp; x: updtab[t] . (x;now)];
  t insert x;
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
  // only timestamps if not in CTP mode
  if[not chainedtp; x: updtab[t] . (x;now)];
  t insert x;
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
  .lg.o[`openlog;"opening logfile: ",string lname];
  h:$[(notexists:not type key lname)or null h0:exec first handle from `..currlog where logname=lname;
    [.[if[notexists;lname;();:;()]];hopen lname];
    h0
  ];
  `..currlog upsert (tab;lname;h);
 };

errorlogname:@[value;`.stplg.errorlogname;`err]

// Error log for failed updates in error mode
openlogerr:{[dir]
  lname:hsym`$string[dir],"/",string[errorlogname],(raze string"dv"$(.z.p+.eodtime.dailyadj)) except".:";
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
  if[null h:`..currlog[tab;`handle];.lg.o[`closelog;"no open handle to log file"];:()];
  .lg.o[`closelog;"closing log file ",string `..currlog[tab;`logname]];
  @[hclose;h;{.lg.e[`closelog;"handle already closed"]}];
  update handle:0N from `..currlog where tbl=tab;
 };

// Roll all logs at end of logging period
rolllog:{[multilog;dir;tabs;p]
  .stpm.updmeta[multilog][`close;tabs;p];
  closelog each tabs;
  @[`.stplg.msgcount;tabs;:;0];
  {[m;d;t]
    .[openlog;(m;d;t;currperiod);
      {.lg.e[`stp;"failed to open log for table ",string[y],": ",x]}[;t]]
  }[multilog;dir;]each tabs;
  .stpm.updmeta[multilog][`open;tabs;p];
 };

// creates dictionary of process data to be used at endofday/endofperiod
endofdaydata:{
  `proctype`procname`tables!(.proc.proctype;.proc.procname;.stpps.t)
 }

// Send close of period message to subscribers, update logging period times
// roll logs if flag is specified - we don't want to roll logs if end-of-day is also going to be triggered
endofperiod:{[p;rolllogs]
  .lg.o[`endofperiod;"executing end of period for ",.Q.s1 `currentperiod`nextperiod!.stplg`currperiod`nextperiod];
  .stpps.endp[.stplg`currperiod;.stplg`nextperiod;.stplg.endofdaydata[]];
  currperiod::nextperiod;
  if[p>nextperiod::multilogperiod+currperiod;
    system"t 0";'"next period is in the past"];
  getnextendUTC[];
  i+::1;
  if[rolllogs;rolllog[multilog;dldir;rolltabs;p]];
  .lg.o[`endofperiod;"end of period complete, new values for current and next period are ",.Q.s1 .stplg`currperiod`nextperiod];
 };

// send end of day to subscribers, close out current logs, roll the day, 
// create new and directory for the next day
endofday:{[p]
  .lg.o[`endofday;"executing end of day for ",.Q.s1 .eodtime.d];
  .stpps.end[.eodtime.d;.stplg.endofdaydata[]];
  if[p>.eodtime.nextroll:.eodtime.getroll[p];system"t 0";'"next roll is in the past"];
  getnextendUTC[];
  .stpm.updmeta[multilog][`close;logtabs;p+.eodtime.dailyadj];
  .stpm.metatable:0#.stpm.metatable;
  closelog each logtabs;
  .eodtime.d+:1;
  init[`. `dbname];
  .lg.o[`endofday;"end of day complete, new value for date is ",.Q.s1 .eodtime.d];
 };

// get the next end time to compare to
getnextendUTC:{nextendUTC::-1+min(.eodtime.nextroll;nextperiod - .eodtime.dailyadj)}

checkends:{
  // jump out early if don't have to do either 
  if[nextendUTC > x; :()];
  if[nextperiod < x1:x+.eodtime.dailyadj; endofperiod[x1;not isendofday:.eodtime.nextroll < x]];
  if[isendofday;if[.eodtime.d<("d"$x)-1;system"t 0";'"more than one day?"];endofday[x]];
 };

init:{[dbname]
  t::tables[`.]except `currlog;
  @[`.stplg.msgcount;t;:;0];
  logtabs::$[multilog~`custom;key custommode;t];
  rolltabs::$[multilog~`custom;logtabs except where custommode in `tabular`none;t];
  currperiod::multilogperiod xbar .z.p+.eodtime.dailyadj;
  nextperiod::multilogperiod+currperiod;
  getnextendUTC[]; 
  createdld[dbname;.eodtime.d];

  if[createlogs;
    openlog[multilog;dldir;;.z.p+.eodtime.dailyadj]each logtabs;
    // read in the meta table from disk 
    .stpm.metatable:@[get;hsym`$string[.stplg.dldir],"/stpmeta";0#.stpm.metatable];
    // set log sequence number to the max of what we've found
    i::1+ -1|exec max seq from .stpm.metatable;
    // add the info to the meta table
    .stpm.updmeta[multilog][`open;logtabs;.z.p+.eodtime.dailyadj];
    ]
 };

\d .


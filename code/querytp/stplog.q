// Utilites for periodic tp logging in stp process

// Live logs and handles to logs for each table
currlog:([tbl:`symbol$()]logname:`symbol$();handle:`int$())

// View of log file handles for faster lookups
loghandles::exec tbl!handle from currlog

\d .stplg

// Name of error log file
errorlogname:@[value;`.stplg.errorlogname;`segmentederrorlogfile]

// Create stp log directory
// Log structure `:stplogs/date/tabname_time
createdld:{[name;date]
  if[not count dir:hsym `$getenv[`KDBTPLOG];.lg.e[`stp;"log directory not defined"];exit 1];
  .os.md dir;
  .os.md .stplg.dldir:` sv dir,`$raze/[string name,"_",date];
 };

// Functions to generate log names in one of five modes

// Generate standardised timestamp string for log names
gentimeformat:{(raze string "dv"$x) except ".:"};

// Tabperiod mode - TP log rolled periodically (default 1 hr), 1 log per table (default setting)
.stplg.logname.tabperiod:{[dir;tab;p] ` sv (hsym dir;`$raze string (.proc.procname;"_";tab),.stplg.gentimeformat[p]) };

// Standard TP mode - write all tables to single log, roll daily
.stplg.logname.singular:{[dir;tab;p] ` sv (hsym dir;`$raze string .proc.procname,"_",.stplg.gentimeformat[p]) };

// Periodic-only mode - write all tables to single log, roll periodically intraday
.stplg.logname.periodic:{[dir;tab;p] ` sv (hsym dir;`$raze string .proc.procname,"_periodic",.stplg.gentimeformat[p]) };

// Tabular-only mode - write tables to separate logs, roll daily
.stplg.logname.tabular:{[dir;tab;p] ` sv (hsym dir;`$raze string (.proc.procname;"_";tab),.stplg.gentimeformat[p]) };

// Custom mode - mixed periodic/tabular mode
// Tables are defined as periodic, tabular, tabperiod or none in config file stpcustom.csv
// Tables not specified in csv are not logged
.stplg.logname.custom:{[dir;tab;p] .stplg.logname[.stplg.custommode tab][dir;tab;p] };

// If in error mode, create an error log name using .stplg.errorlogname
.stplg.logname.error:{[dir;ename;p] ` sv (hsym dir;`$raze string (.proc.procname;"_";ename),.stplg.gentimeformat[p]) };

// Update and timer functions in three batch modes ////////////////////////////////////
// preserve pre-existing definitions
upd:@[value;`.stplg.upd;enlist[`]!enlist ()];
zts:@[value;`.stplg.zts;enlist[`]!enlist ()];

// Functions to add columns on updates
updtab:@[value;`.stplg.updtab;enlist[`]!enlist {(enlist(count first x)#y),x}]

// If set to memorybatch, publish and write to disk will be run in batches
// insert to table in memory, on a timer flush the table to disk and publish, update counts
upd[`memorybatch]:{[t;x;now]
  t insert updtab[t] . (x;now);
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
  x:$[0h>type last x;enlist;flip] .stpps.tabcols[t]!x;
  @[`.stplg.msgcount;t;+;1];
  @[`.stplg.rowcount;t;+;count x];
  .stpps.pub[t;x]
 };

zts[`immediate]:{}

//////////////////////////////////////////////////////////////////////////////////////

// Functions to obtain logs for client replay ////////////////////////////////////////
// replaylog called from client-side, returns nested list of logcounts and lognames
replaylog:{[t]
  getlogs[replayperiod][t]
 }

// alternative replay allows for 'pass through logging'
// if SCTP not producing logs, subscribers replay from STP log files
if[.sctp.loggingmode=`parent;
  replaylog:{[t]
    .sctp.tph (`.stplg.replaylog; t)
    }
  ]

getlogs:enlist[`]!enlist ()

// If replayperiod set to `period, only replay logs for current logging period
getlogs[`period]:{[t]
  distinct flip (.stplg.msgcount;exec tbl!logname from `..currlog where tbl in t)@\:t
 };

// If replayperiod set to `day, replay all of today's logs
getlogs[`day]:{[t]
  // set the msgcount to 0Wj for all logs which have closed
  lnames:select seq,tbls,logname,msgcount:0Wj from .stpm.metatable where any each tbls in\: t;
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
    [if[notexists;.[lname;();:;()]];hopen lname];
    h0
  ];
  `..currlog upsert (tab;lname;h);
 };

// Error log for failed updates in error mode
openlogerr:{[dir]
  lname:.[.stplg.logname.error;(dir;.stplg.errorlogname;.z.p+.eodtime.dailyadj);{.lg.e[`openlogerr;"failed to make error log: ",x]}];
  if[not type key lname;.[lname;();:;()]];
  h:@[{hopen x};lname;{.lg.e[`openlogerr;"failed to open handle to error log with error: ",x]}];
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

// Creates dictionary of process data to be used at endofday/endofperiod - configurable but default provided
endofdaydata:@[value;`.stplg.endofdaydata;{ {`proctype`procname`tables!(.proc.proctype;.proc.procname;.stpps.t)} }];

// endofperiod function defined in SCTP
// passes on eop messages to subscribers and rolls logs
endofperiod:{[currentpd;nextpd;data]
  .lg.o[`endofperiod;"flushing remaining data to subscribers and clearing tables"];
  .stpps.pubclear[.stplg.t];
  .lg.o[`endofperiod;"executing end of period for ",.Q.s1 `currentperiod`nextperiod!(currentpd;nextpd)];
  .stpps.endp[currentpd;nextpd;data];                   // sends endofperiod message to subscribers
  currperiod::nextpd;                                   // increments current period
  if[.sctp.loggingmode=`create;periodrollover[data]]    // logs only rolled if in create mode
  };

// stp runs function to send out end of period messages and roll logs
// eop log roll is stopped if eod is also going to be triggered (roll is not stopped in SCTP)
stpeoperiod:{[currentpd;nextpd;data;rolllogs]
  .lg.o[`stpeoperiod;"passing on endofperiod message to subscribers"];
  .stpps.endp[currentpd;nextpd;data];                      // sends endofperiod message to subscribers
  currperiod::nextperiod;                                  // increments current period
  if[(data`p)>nextperiod::multilogperiod+currperiod;
    system"t 0";'"next period is in the past"];            // timer off
  getnextendUTC[];                                         // grabs next end time
  if[rolllogs;periodrollover[data]];                       // roll if appropriate
  .lg.o[`stpeoperiod;"end of period complete, new values for current and next period are ",.Q.s1 (currentpd;nextpd)];
  }

// common eop log rolling logic for STP and SCTP
periodrollover:{[data]
  i+::1;  // increments log seq number
  rolllog[multilog;dldir;rolltabs;data`p];
  }

// endofday function defined in SCTP
// passes on eod messages to subscribers and rolls logs
endofday:{[date;data]
  .lg.o[`endofday;"flushing remaining data to subscribers and clearing tables"];
  .stpps.pubclear[.stplg.t];
  .stpps.end[date;data];  // sends endofday message to subscribers
  dayrollover[data];
  }

// STP runs function to send out eod messages and roll logs
stpeod:{[date;data]
  .lg.o[`stpeod;"executing end of day for ",.Q.s1 .eodtime.d];
  .stpps.end[date;data];                                         // sends endofday message to subscribers
  dayrollover[data];                 
 }

// common eod log rolling logic for STP and SCTP
dayrollover:{[data]
  if[(data`p)>.eodtime.nextroll:.eodtime.getroll[data`p];
    system"t 0";'"next roll is in the past"];                    // timer off
  getnextendUTC[];                                               // grabs next end time
  .eodtime.d+:1;                                                 // increment current day
  .stpm.updmeta[multilog][`close;logtabs;(data`p)+.eodtime.dailyadj];   // update meta tables
  .stpm.metatable:0#.stpm.metatable;
  closelog each logtabs;                                                // close current day logs
  init[string .proc.procname];                                          // reinitialise process
  .lg.o[`dayrollover;"end of day complete, new value for date is ",.Q.s1 .eodtime.d];
  }

// get the next end time to compare to
getnextendUTC:{nextendUTC::-1+min(.eodtime.nextroll;nextperiod - .eodtime.dailyadj)}

checkends:{
  // jump out early if don't have to do either
  if[nextendUTC > x; :()];
  // check for endofperiod
  if[nextperiod < x1:x+.eodtime.dailyadj; stpeoperiod[.stplg`currperiod;.stplg`nextperiod;.stplg.endofdaydata[],(enlist `p)!enlist x1;not .eodtime.nextroll < x]];
  // check for endofday
  if[.eodtime.nextroll < x;if[.eodtime.d<("d"$x)-1;system"t 0";'"more than one day?"]; stpeod[.eodtime.d;.stplg.endofdaydata[],(enlist `p)!enlist x]];
 };

init:{[dbname]
  t::tables[`.]except `currlog;
  msgcount::rowcount::t!count[t]#0;
  tmpmsgcount::tmprowcount::(`symbol$())!`long$();
  logtabs::$[multilog~`custom;key custommode;t];
  rolltabs::$[multilog~`custom;logtabs except where custommode in `tabular`singular;t];
  currperiod::multilogperiod xbar .z.p+.eodtime.dailyadj;
  nextperiod::multilogperiod+currperiod;
  getnextendUTC[];
  i::1;
  seqnum::0;
  
  if[(value `..createlogs) or .sctp.loggingmode=`create;
    createdld[dbname;.eodtime.d];
    openlog[multilog;dldir;;.z.p+.eodtime.dailyadj]each logtabs;
    // If appropriate, roll error log
    if[.stplg.errmode;openlogerr[dldir]];
    // read in the meta table from disk 
    .stpm.metatable:@[get;hsym`$string[.stplg.dldir],"/stpmeta";0#.stpm.metatable];
    // set log sequence number to the max of what we've found
    i::1+ -1|exec max seq from .stpm.metatable;
    // add the info to the meta table
    .stpm.updmeta[multilog][`open;logtabs;.z.p+.eodtime.dailyadj];
    ]

  // set loghandles to null if sctp is not creating logs
  if[.sctp.chainedtp and not .sctp.loggingmode=`create;
    `..loghandles set t! (count t) # enlist  (::)
   ]
 };

\d .

// Close logs on clean exit
.z.exit:{
  if[not x~0i;.lg.e[`stpexit;"Bad exit!"];:()];
  .lg.o[`stpexit;"Exiting process"];
  // exit before logs are touched if process is an sctp NOT in create mode
  if[.sctp.chainedtp and not .sctp.loggingmode=`create; :()];
  .lg.o[`stpexit;"Closing off log files"];
  .stpm.updmeta[.stplg.multilog][`close;.stpps.t;.z.p];
  .stplg.closelog each .stpps.t;
 }

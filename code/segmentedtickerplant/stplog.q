// Utilites for periodic tp logging in stp process

\d .stplg

// Create stp log directory
// Log structure `:stplogs/date/tabname_time
createdld:{[name;date]
  $[count dir:getenv[`KDBSTPLOG];
    .os.md dldir::hsym`$raze dir,"/",string name,date;
    [.lg.e[`stp;"log directory not defined"];exit]
  ]
 };

// Default stp mode is tabperiod
// TP log rolled periodically (default 1 hr), 1 log per table
logname.tabperiod:{[dir;tab;logfreq;dailyadj]
  ` sv(hsym dir;`$string[tab],ssr[;;""]/[-13_string logfreq xbar .z.p+dailyadj;":.D"])
 };

// Standard TP mode - to be added
logname.none:{[dir;tab;logfreq;dailyadj]}

// Custom mode
// Default writes all tables to single log, rolls hourly
// Can be overwritten by ueser
logname.custom:{[dir;tab;logfreq;dailyadj]
  ` sv(hsym dir;`$"custom",ssr[;;""]/[-13_string logfreq xbar .z.p+dailyadj;":.D"]) 
 };

// Live logs and handles to logs for each table
currlog:([tbl:`symbol$()]logname:`symbol$();handle:`int$())

msgcount:enlist[`]!enlist ()

openlog:{[multilog;dir;tab;logfreq;dailyadj]
  lname:logname[multilog][dir;tab;logfreq;dailyadj];
  h:$[not type key lname;
    [.[lname;();:;()];hopen lname];
    exec first handle from .stplg.currlog where logname=lname
  ];
  `.stplg.currlog upsert (tab;lname;h);
 };

// Error log for failed updates in error mode
openlogerr:{[dir]
  lname:` sv(hsym dir;`$"errdatabase",string .z.d);
  if[not type key lname;.[lname;();:;()]];
  h:hopen lname;
  `.stplg.currlog upsert (`err;lname;h);
 };

// Log failed message and error type in error mode
badmsg:{[e;t;x]
  .lg.o[`upd;"Bad message received, error: ",e];
  .stplg.handles[`err] enlist(`upderr;t;x);
 };

closelog:{[tab]
  if[null h:currlog[tab;`handle];.lg.o[`closelog;"No open handle to log file"];:()];
  @[hclose;h;.lg.e[`closelog;"Handle already closed"]];
  update handle:0N from `.stplg.currlog where tbl=tab;
 };

rolllog:{[multilog;dir;tab;logfreq;dailyadj]
  .stpm.updmeta[multilog][`close;tab;.z.p];
  closelog each tab;
  i+::1;
  @[`.stplg.msgcount;tab;:;0];
  openlog[multilog;dir;;logfreq;dailyadj]each tab;
  .stpm.updmeta[multilog][`open;tab;.z.p];
 };

endofperiod:{
  .stpps.endp . .eodtime`p`nextperiod;
  .eodtime.currperiod:.eodtime.nextperiod;
  if[.z.p>.eodtime.nextperiod:.eodtime.getperiod[.z.p;multilogperiod;.eodtime.currperiod];
    system"t 0";'"next period is in the past"];
  rolllog[multilog;dldir;t;multilogperiod;0D01];
 };

endofday:{
  .stpps.end d;
  d+:1;
  if[.z.p>.eodtime.nextroll:.eodtime.getroll[.z.p];system"t 0";'"next roll is in the past"];
  .eodtime.dailyadj:.eodtime.getdailyadjustment[];
  closelog each t;
  init[];
 };

ts:{
  if[.eodtime.nextperiod < x; endofperiod[]];
  if[.eodtime.nextroll < x;if[d<("d"$x)-1;system"t 0";'"more than one day?"];endofday[]];
 };

init:{
  .stplg.t:tables`.;
  .stplg.d:.eodtime.d;
  .stplg.i:0;
  @[`.stplg.msgcount;t;:;0];
  .eodtime.currperiod:multilogperiod xbar .z.p;
  .eodtime.nextperiod:.eodtime.getperiod[.z.p;multilogperiod;.eodtime.currperiod];
  createdld[`database;.z.d];
  openlog[multilog;dldir;;0D00:00:00.001;0D00]each t;
  .stplg.handles::exec tbl!handle from .stplg.currlog;
  .stpm.updmeta[multilog][`open;t;.z.p];
 };

\d .


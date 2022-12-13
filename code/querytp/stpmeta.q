// API for writing logfile meta data
// Metatable keeps info on all opened logs, the tables which feed each log, and the number of messages written to each log

\d .stpm

metatable:([]seq:`int$();logname:`$();start:`timestamp$();end:`timestamp$();tbls:();msgcount:`int$();schema:();additional:())

// Functions to update meta data for all logs in each logging mode
// Meta is updated only when opening and closing logs
updmeta:enlist[`]!enlist ()

updmeta[`tabperiod]:{[x;t;p]
  getmeta[x;p;;]'[enlist each t;`..currlog[([]tbl:t)]`logname];
  setmeta[.stplg.dldir;metatable];
 };

updmeta[`singular]:{[x;t;p]
  getmeta[x;p;t;`..currlog[first t]`logname];
  setmeta[.stplg.dldir;metatable];
 };

updmeta[`periodic]:updmeta[`singular]

updmeta[`tabular]:updmeta[`tabperiod]

updmeta[`custom]:{[x;t;p]
  pertabs:where `periodic=.stplg.custommode;
  updmeta[`periodic][x;t inter pertabs;p];
  updmeta[`tabular][x;t except pertabs;p]
 };

// Logname, start time, table names and schema populated on opening
// End time and final message count updated on close
// Sequence number increments by one on log period rollover
getmeta:{[x;p;t;ln]
  if[x~`open;
    s:((),t)!(),.stpps.schemas[t];
    `.stpm.metatable upsert (.stplg.i;ln;p;0Np;t;0;s;enlist ()!());
  ];
  if[x~`close;
    update end:p,msgcount:sum .stplg.msgcount[t] from `.stpm.metatable where logname = ln
  ]
 };

setmeta:{[dir;mt]
  t:(hsym`$string[dir],"/stpmeta");
  .[{x set y};(t;mt);{.lg.e[`setmeta;"Failed to set metatable with error: ",x]}];
 };


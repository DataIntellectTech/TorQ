// API for writing logfile meta data
// Metatable keeps info on all opened logs, the tables which feed each log, and the number of messages written to each log

\d .stpm

metatable:([]seq:`int$();logname:`$();start:`timestamp$();end:`timestamp$();tbls:();msgcount:`int$();schema:();additional:())

// Functions to update meta data for all logs in each logging mode
// Meta is updated only when opening and closing logs
updmeta:enlist[`]!enlist ()

updmeta[`tabperiod]:{[x;t;p]
  getmeta[x;p;;]'[enlist each t;`..currlog[([]tbl:t)]`logname];
  (hsym`$string[.stplg.dldir],"/stpmeta") set metatable;
 };

updmeta[`none]:{[x;t;p]
  getmeta[x;p;t;`..currlog[first t]`logname];
  (hsym`$string[.stplg.dldir],"/stpmeta") set metatable;
 };

updmeta[`periodic]:updmeta[`none]

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
    s:((),t)!0#/:value each (),t;
    `.stpm.metatable upsert (.stplg.i;ln;p;0Np;t;0;s;enlist ()!());
  ];
  if[x~`close;
    ![`.stpm.metatable;enlist (=;`logname;`ln);0b;`end`msgcount!(p;(sum;(`.stplg.msgcount;`t)))]
  ]
 };


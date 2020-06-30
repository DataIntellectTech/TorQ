// API for writing logfile meta data

\d .stpm

metatable:([]seq:`int$();logname:`$();start:`timestamp$();end:`timestamp$();tabname:();msgcount:`int$();schema:();additional:())

updmeta.tabperiod:{[x;t;p]
  getmeta[x;p;;]'[enlist each t;.stplg.currlog[([]tbl:t)]`logname];
  (hsym`$string[.stplg.dldir],"/stpmeta") set metatable;
 };

updmeta.custom:{[x;t;p]
  getmeta[x;p;t;.stplg.currlog[first t]`logname];
  (hsym`$string[.stplg.dldir],"/stpmeta") set metatable;
 };

getmeta:{[x;p;t;ln]
  if[x~`open;
    s:((),t)!0#/:value each (),t;
    `.stpm.metatable upsert (.stplg.i;ln;p;0Np;t;0;s;enlist ()!());
  ];
  if[x~`close;
    ![`.stpm.metatable;enlist (=;`logname;`ln);0b;`end`msgcount!(p;(sum;(`.stplg.msgcount;`t)))]
  ]
 };


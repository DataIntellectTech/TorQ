// API for writing logfile meta data

\d .stpm

metatable:([]logname:`$();start:`timestamp$();end:`timestamp$();tabname:`$();schema:();additional:())

updmeta:{[x;ln;t]
  if[x~`open;
    c:-11!(-2;.stplg.currlog[t;`logname]);
    s:enlist ((),t)!value each (),t;
    `.stpm.metatable upsert (ln;.z.p;0Np;t;enlist s;enlist ()!());
  ];
  if[x~`close;
    [`.stpm.metatable;enlist (=;`logname;`ln);0b;enlist[`end]!enlist .z.p]
  ]
  (hsym`$string[.stplg.dldir],"/stpmeta") set metatable
 };


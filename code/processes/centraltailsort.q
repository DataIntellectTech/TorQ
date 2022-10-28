\d .ts

taildir:hsym `$getenv`KDBTAIL;                                             /-load in taildir env variables
hdbdir:hsym `$getenv`KDBHDB;                                               /-load in hdb env variables
rdbtypes:@[value;`rdbtypes;`rdb];                                          /- rdbs to send reset window message to
savelist:@[value;`savelist;`quote`trade];                                  /-list of tables to save to HDB
taildbs:key taildir;                                                       /-list of tailDBs that need saved to HDB
taildirs:();                                                               /-empty list to append tailDB paths to - to be used
                                                                           / when HDB save is complete to delete tailDB partitions
.servers.startup[];

\d .

tailmsg:0;                                                                  /-counter for each segmented tailsort completion

addpattr:{[hdbdir;pt;tabname]
  /-load column to add p attribute on
  pcol:.ds.loadtablekeycols[][tabname];
  /-add p attr to on-disk table
  .lg.o[`attr;"adding p attribute to the ",string[pcol]," col in ",string[tabname]];
  addattr:{[hdbdir;pt;tabname;pcol]
    @[.Q.par[hdbdir;pt;tabname];pcol;`p#]
  };
  .[addattr;
    (hdbdir;pt;tabname;pcol);
    {[e] .lg.e[`attr;"Failed to add attr : ",e]}
  ];
  };

/- notify rdb when tail sort process complete
resetrdbwindow:{
  .lg.o[`rdbwindow;"resetting rdb moving time window"];
  rdbprocs:.servers.getservers[`proctype;.ts.rdbtypes;()!();1b;0b];
  {neg[x]".rdb.tailsortcomplete:1b"}each exec w from rdbprocs;
  };

deletetaildb:{[tdbpath]
  /-function to delete tailDB
  .lg.o[`clearTDB;"removing TDB data for partition ",string[tdbpath]];
  @[.os.deldir; tdbpath; {[e] .lg.e[`load;"failed to delete TDB : ",e]}];
  };

savecomplete:{[pt;tablelist]
  /-function to add p attr to HDB tables, delete tailDBs
  addpattr[.ts.hdbdir;pt;] each tablelist;
  tailmsg::0;
  .ts.taildirs:();
  resetrdbwindow[];
  };

taildirpath:{[taildir]
  /- function to delete taildb partition
  deletetaildb[taildir];
  .lg.o[`endofday;"end of day deletion of partition ",string[taildir]," now completed"];
 };

endofday:{[pt;procname]
  /- function to trigger data load & save to HDB once endofday message is received from tailer(s)
  tailmsg+::1;
  .lg.o[`endofday;"end of day message received from ",string[procname]," - ",string[pt]];
  if[tailmsg = count .ts.taildbs; savecomplete[pt;.ts.savelist]];
  };

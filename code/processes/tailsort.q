\d .ts

taildir:hsym `$getenv`KDBTAIL;                                             /-load in taildir env variables
hdbdir:hsym `$getenv`KDBHDB;                                               /-load in hdb env variables
rdbtypes:@[value;`rdbtypes;`rdb];                                          /- rdbs to send reset window message to
.tsw.tailsortworkertypes:`$"tailsortworker_",last "_" vs string .proc.proctype;    /-list of tailsort types to look for upon a sort being called with worker process
.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.tsw.tailsortworkertypes) except `
.servers.startup[];
/ - define .z.pd in order to connect to any worker processes
.z.pd:{$[.z.K<3.3;
        `u#`int$();
	`u#exec w from .servers.getservers[`proctype;.tsw.tailsortworkertypes;()!();1b;0b]]
        }

savelist:@[value;`savelist;`quote`trade];                                  /-list of tables to save to HDB
taildbs:key taildir;                                                       /-list of tailDBs that need saved to HDB
taildirs:();                                                               /-empty list to append tailDB paths to - to be used
                                                                           / when HDB save is complete to delete tailDB partitions
\d .

savescompleted:0;                                                          /-variable to count how many tailDBs have been saved to HDB

mergebypart:{[dir;pt;tabname;dest]
  /-function to merge table partitions from tailDB and save to HDB
  /-get list of partitions to be merged
  parts:(key dir) except `access;
  partdirs:{` sv (x;y;z)}[dir;;tabname] each parts;
  /-load data from each partition
  .lg.o[`merge;"reading partition(s) ", (", " sv string[partdirs])];
  data:get each partdirs;
  /-if multiple partitions have been read in data will be a list of tabs, if this is the case - join into single tab
  if[98<>type data;data:raze data];
  /-upsert data to partition in destination directory
  dest:` sv .Q.par[dest;pt;tabname],`;
  .[upsert;
    (dest;data);
    {[e] .lg.e[`upserttopartition;"failed to save table to disk : ",e];'e}
  ];
  };

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
  /-split between workers if workers exist
  $[(0 < count .z.pd[]) and ((system "s")<0);
    addpattr[.ts.hdbdir;pt;] peach tablelist;
    addpattr[.ts.hdbdir;pt;] each tablelist;
   ];
  deletetaildb each .ts.taildirs;
  /-reset savescompleted counter and .ts.taildirs
  savescompleted::0;
  .ts.taildirs:();
  resetrdbwindow[];
  };

loadandsave:{[pt;procname]
  /-function to merge tables from subpartitions in tailDB and save to HDB
  taildir:` sv (.ts.taildir;procname;`$string pt);
  .ts.taildirs,:taildir;
  /-merge tables from tailDBs and save to HDB
  /-split between workers if workers exist
  $[(0 < count .z.pd[]) and ((system "s")<0);
    mergebypart[taildir;pt;;.ts.hdbdir] peach .ts.savelist;
    mergebypart[taildir;pt;;.ts.hdbdir] each .ts.savelist;
   ];
  /-increase savescompleted counter
  savescompleted+::1;
  .lg.o[`sortcomplete;"end of day sort complete for ",string[procname]];
  /-check if all eod saves have been completed, if so trigger savecomplete
  if[savescompleted = count .ts.taildbs;savecomplete[pt;.ts.savelist]];
  };

endofday:{[pt;procname]
  /- function to trigger data load & save to HDB once endofday message is received from tailer(s)
  .lg.o[`endofday;"end of day message received from ",string[procname]," - ",string[pt]];
  loadandsave[pt;procname];
  };

/.servers.startup[];

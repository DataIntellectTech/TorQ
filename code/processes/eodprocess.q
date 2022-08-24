\d .eod

taildir:hsym `$getenv`KDBTAIL;                                             /-load in taildir env variables
hdbdir:hsym `$getenv`KDBHDB;                                               /-load in hdb env variables
ignorelist:@[value;`ignorelist;`heartbeat`logmsg];                         /-list of tables to ignore
taildbs:key taildir;                                                       /-list of tailDBs that need saved to HDB
taildirs:();                                                               /-empty list to append tailDB paths to - to be used
                                                                           / when HDB save is complete to delete tailDB partitions
\d .

savescompleted:0;                                                          /-variable to check how many tailDBs have been saved to HDB

endofday:{[pt;procname]
  /- function to trigger data load & save to HDB once endofday message is received from tailer(s)
  .lg.o[`endofday;"end of day message received from ",string[procname]," - ",string[pt]];
  loadandsave[pt;procname];
  };

loadandsave:{[pt;procname]
  /- function to load TDB data and save data to HDB
  taildir:`$1_string ` sv (.eod.taildir;procname;`$string pt);
  .eod.taildirs,:taildir;
  .lg.o[`load;"loading TDB data from ",string[procname]];
  @[.Q.l; taildir; {[e] .lg.e[`load;"Failed to load TDB : ",e]}];

  /-define list of tables to be saved to HDB
  tablelist:tables[] except .eod.ignorelist;

  /-save tables to HDB
  savetables[.eod.hdbdir;pt;tablelist];
  savescompleted+::1;

  .lg.o[`eodcomplete;"end of day sort complete for ",string[procname]];

  /-check if all eod saves have been completed, if so trigger savecomplete
  if[savescompleted = count .eod.taildbs;savecomplete[pt;tablelist]];
  };

savecomplete:{[pt;tablelist]
  /-function to add p attr to HDB tables, delete tailDBs
  addpattr[.eod.hdbdir;pt;] each tablelist;
  deletetaildb each .eod.taildirs;

  /-reset savescompleted counter and .eod.taildirs
  savescompleted::0;
  .eod.taildirs:();
  };

upserttopartition:{[dir;pt;tabname]
  /-create directory path data will be saved to
  /-need to delete int col from tables before they can be saved to HDB
  directory:(` sv .Q.par[dir;pt;tabname],`);
  data:delete int from select from tabname;

  .lg.o[`save;"saving ",string[tabname]," data to HDB"];

  /-upsert data to partition in directory
  .[upsert;
    (directory;data);
    {[e] .lg.e[`upserttopartition;"failed to save table to disk : ",e];'e}
  ];
  };

savetables:{[dir;pt;tablist]  
  /-check if current partition exists in HDB, create it if not
  if[not (`$string pt) in dir;.os.md[` sv (dir;`$string pt)]];

  /-upsert table to directory partition
  upserttopartition[dir;pt;] each tablist;
  };

addpattr:{[hdbdir;pt;tabname]
  /-load column to add p attribute on
  pcol:.ds.loadtablekeycols[][tabname];

  /-add p attr to on-disk table
  addattr:{[hdbdir;pt;tabname;pcol] @[.Q.par[hdbdir;pt;tabname];pcol;`p#]};
  .lg.o[`attr;"adding p attribute to the ",string[pcol]," col in ",string[tabname]];

  .[addattr;
    (hdbdir;pt;tabname;pcol);
    {[e] .lg.e[`attr;"Failed to add attr : ",e];e}
  ];
  };

deletetaildb:{[tdbpath]
  /-function to delete tailDB
  .lg.o[`clearTDB;"removing TDB data for partition ",string[tdbpath]];
  @[.os.deldir; tdbpath; {[e] .lg.e[`load;"failed to delete TDB : ",e]}];
  };

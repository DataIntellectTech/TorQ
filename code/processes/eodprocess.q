\d .eod

taildir:hsym `$getenv`KDBTAIL;                                             /-load in taildir env variables
hdbdir:hsym `$getenv`KDBHDB;                                               /-load in hdb env variables
savelist:@[value;`savelist;`quote`trade];                                  /-list of tables to save to HDB
taildbs:key taildir;                                                       /-list of tailDBs that need saved to HDB
taildirs:();                                                               /-empty list to append tailDB paths to - to be used
                                                                           / when HDB save is complete to delete tailDB partitions
\d .

savescompleted:0;                                                          /-variable to count how many tailDBs have been saved to HDB

endofday:{[pt;procname]
  /- function to trigger data load & save to HDB once endofday message is received from tailer(s)
  .lg.o[`endofday;"end of day message received from ",string[procname]," - ",string[pt]];
  loadandsave[pt;procname];
  };

loadandsave:{[pt;procname]
  /-function to merge tables from subpartitions in tailDB and save to HDB
  taildir:` sv (.eod.taildir;procname;`$string pt);
  .eod.taildirs,:taildir;

  /-merge tables from tailDBs and save to HDB
  mergebypart[taildir;pt;;.eod.hdbdir] each .eod.savelist;

  /-increase savescompleted counter
  savescompleted+::1;

  .lg.o[`eodcomplete;"end of day sort complete for ",string[procname]];

  /-check if all eod saves have been completed, if so trigger savecomplete
  if[savescompleted = count .eod.taildbs;savecomplete[pt;.eod.savelist]];
  };

mergebypart:{[dir;pt;tabname;dest]
  /-function to merge table partitions from tailDB and save to HDB
  /-get list of partitions to be merged
  ints:key dir;
  partdirs:{` sv (x;y;z)}[dir;;tabname] each ints;

  /-load data from each partition
  .lg.o[`merge;"reading partition(s) ", (", " sv string[partdirs])];
  data:get each partdirs;

  /-if multiple partitions have been read in data will be a list of tabs, if this is the case - join into single tab
  if[98<>type data;data:(,/)data];

  /-upsert data to partition in destination directory
  dest:` sv .Q.par[dest;.z.d;tabname],`;
  .[upsert;
    (dest;data);
    {[e] .lg.e[`upserttopartition;"failed to save table to disk : ",e];'e}
  ];
  };

savecomplete:{[pt;tablelist]
  /-function to add p attr to HDB tables, delete tailDBs
  addpattr[.eod.hdbdir;pt;] each tablelist;
  deletetaildb each .eod.taildirs;

  /-reset savescompleted counter and .eod.taildirs
  savescompleted::0;
  .eod.taildirs:();
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
    {[e] .lg.e[`attr;"Failed to add attr : ",e];e}
  ];
  };

deletetaildb:{[tdbpath]
  /-function to delete tailDB
  .lg.o[`clearTDB;"removing TDB data for partition ",string[tdbpath]];
  @[.os.deldir; tdbpath; {[e] .lg.e[`load;"failed to delete TDB : ",e]}];
  };

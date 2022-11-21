\d .ts

taildir:hsym `$getenv`KDBTAIL;                                             /-load in taildir env variables
hdbdir:hsym `$getenv`KDBHDB;                                               /-load in hdb env variables
rdbtypes:@[value;`rdbtypes;`rdb];                                          /- rdbs to send reset window message to
/tailsortworkertypes:`$"tailsortworker_",last "_" vs string .proc.proctype; /-list of tailsort types to look for upon a sort being called with worker process
.tailer.tailreadertypes:`$"tr_",last "_" vs string .proc.proctype;
savelist:@[value;`savelist;`quote`trade`quote1`trade1`quote2`trade2];                                  /-list of tables to save to HDB
/-taildirseg:raze (getenv`KDBTAIL),"/tailer",(string .ds.segmentid),"/",(string .tr.currentpartition);
taildbs:key taildir;                                                       /-list of tailDBs that need saved to HDB
taildirs:();                                                               /-empty list to append tailDB paths to - to be used
                                                                           / when HDB save is complete to delete tailDB partitions
/ - define .z.pd in order to connect to any worker processes
.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.tailer.tailreadertypes);
.servers.startup[];

\d .

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
  .lg.o[`upserttopartition;"starting to save table to disk"];
  dest:` sv .Q.par[dest;pt;tabname],`;
  .[upsert;
    (dest;data);
    {[e] .lg.e[`upserttopartition;"failed to save table to disk : ",e];'e}
  ];
  };

loadandsave:{[pt;procname;tabname]
  taildir:` sv (.ts.taildir;procname;`$string pt);
  mergebypart[taildir;pt;tabname;.ts.hdbdir];
  cts:exec w from .servers.getservers[`proctype;`centraltailsort;()!();1b;0b];
  if[0=count cts;
    .lg.e[`connection;"no connection to the centraltailsort could be established, failed to send end of day message"];:()];
  /- notify centraltailsort process
  neg[first cts](`notify;.proc.procname;.proc.proctype);
    .lg.o[`eod;"table savedown message sent to centraltailsort process"];
  .lg.o[`sortcomplete;"table savedown complete for ",string[procname]];
  };

endofday:{[pt;procname;tabname]
  /- function to trigger data load & save to HDB once centraltailsort message comes through
  .lg.o[`endofday;"end of day message received from ",string[procname]," - ",string[pt]];
  loadandsave[pt;procname;tabname];
  };

deletetaildb:{[tdbpath]
  /-function to delete tailDB
  .lg.o[`clearTDB;"removing TDB data for partition ",string[tdbpath]];
  @[.os.deldir; tdbpath; {[e] .lg.e[`load;"failed to delete TDB : ",e]}];
 };

/-delete&reload:{[]
  /-trigger the deletion of current taildb
  /-.lg.o[`eod;"begining deletion and reload od taildb data"];
  /-calling deletetaildb function
  /-deletetaildb[.ts.taildir];
  /-tr:first exec w from .servers.getservers[`proctype;.tailer.tailreadertypes;()!();1b;0b]
  /-neg[tr](`endofday;.z.d);
  /-.lg.o[`eod;"completed deletion and reload of taildb data"];
 /-};
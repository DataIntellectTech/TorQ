\d .ts

taildir:hsym `$getenv`KDBTAIL;                                             /-load in taildir env variables
hdbdir:hsym `$getenv`KDBHDB;                                               /-load in hdb env variables
.tailer.tailreadertype:`$first .proc.params[`tailreadertype];              /-use .proc.params to get associated tailreader
.tailer.rdbtype:`$first .proc.params[`rdbtype];                            /-use .proc.params to get associated rdb
savelist:@[value;`savelist;`quote`trade];                                  /-list of tables to save to HDB
taildbs:key taildir;                                                       /-list of tailDBs that need saved to HDB

.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.tailer.tailreadertype,.tailer.rdbtype);
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
  dest:` sv .Q.par[dest;pt;tabname],`;
  .[upsert;
    (dest;data);
    {[e] .lg.e[`upserttopartition;"failed to save table to disk : ",e]}
  ];
  };

loadandsave:{[pt;procname;tabname]
  /-function that calls mergebypart, then establishes a connection
  /-to the centraltailsort and sends it a responce once savedown is complete
  taildir:` sv (.ts.taildir;procname;`$string pt);
  mergebypart[taildir;pt;tabname;.ts.hdbdir];
  cts:exec w from .servers.getservers[`proctype;`centraltailsort;()!();1b;0b];
  if[0=count cts;
    .lg.e[`connection;"no connection to the centraltailsort could be established, failed to send end of day message"];:()];
  /- notify centraltailsort process
  neg[first cts](`notify;.proc.procname;.proc.proctype;.ds.segmentid 0);
    .lg.o[`endofday;"table savedown message sent to centraltailsort process"];
  .lg.o[`sortcomplete;"table ",string[tabname], " savedown complete"];
  };

deletetaildb:{[tdbpath]
  /-function to delete tailDB
  .lg.o[`clearTDB;"removing TDB data for partition ",string[tdbpath]];
  @[.os.deldir; tdbpath; {[e] .lg.e[`load;"failed to delete TDB : ",e]}];
  };

endofdayreload:{[pt;procname;tailerprocname]
 .lg.o[`notify;"endofday notify and delete message received from ",string[procname]];
 taildir:` sv (.ts.taildir;tailerprocname;`$string pt);
 .lg.o[`connection;"attempting connection to ",string[.tailer.tailreadertype]];
 tr:first exec w from .servers.getservers[`proctype;.tailer.tailreadertype;()!();1b;0b];
 if[0=count tr;
    .lg.e[`connection;"no connection to the ",(string .tailer.tailreadertype)," could be established, failed to send end of day message"];:()];
 neg[tr](`endofday;pt);
 .lg.o[`endofday;"endofday message sent to ",string[.tailer.tailreadertype]];
 deletetaildb[taildir];
 .lg.o[`endofday;"end of day deletion of partition ",string[taildir]," now completed"];
 };

endofday:{[pt;tailerproc;procname;tabname]
  /- function to trigger data load & save to HDB once centraltailsort message comes through
  .lg.o[`endofday;"end of day message received from ",string[procname]," - ",string[pt]];
  loadandsave[pt;tailerproc;tabname];
  };

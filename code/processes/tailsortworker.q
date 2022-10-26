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
    {[e] .lg.e[`upserttopartition;"failed to save table to disk : ",e];'e}
  ];
  };
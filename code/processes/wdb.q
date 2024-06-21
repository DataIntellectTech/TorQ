/http://code.kx.com/wsvn/code/contrib/simon/tick/w.q
/-subscribes to tickerplant and appends data to disk after the in-memory table exceeds a specified number of rows
/-the row check is set on a timer - the interval may be specified by the user
/-at eod the on-disk data may be sorted and attributes applied as specified in the sort.csv file

.merge.mergebybytelimit:@[value;`.merge.mergebybytelimit;0b];              /- merge limit configuration - default is 0b row count limit, 1b is bytesize limit

\d .wdb

/- define default parameters
mode:@[value;`mode;`saveandsort];                                          /-the wdb process can operate in three modes
                                                                           /- 1. saveandsort               -               the process will subscribe for data,
                                                                           /-                                              periodically write data to disk and at EOD it will flush
                                                                           /-                                              remaining data to disk before sorting it and informing
                                                                           /-                                              GWs, RDBs and HDBs etc...
                                                                           /- 2. save                      -               the process will subscribe for data,
                                                                           /-                                              periodically write data to disk and at EOD it will flush
                                                                           /-                                              remaining data to disk.  It will then inform it's respective
                                                                           /-                                              sort mode process to sort the data
                                                                           /- 3. sort                      -               the process will wait to get a trigger from it's respective
                                                                           /-                                              save mode process.  When this is triggered it will sort the
                                                                           /-                                              data on disk, apply attributes and the trigger a reload on the
                                                                           /-                                              rdb and hdb processes

writedownmode:@[value;`writedownmode;`default];                            /-the wdb process can periodically write data to disc and sort at EOD in two ways:
                                                                           /- 1. default                   -       the data is partitioned by [ partitiontype ]
                                                                           /-                                      at EOD the data will be sorted and given attributes according to sort.csv before being moved to hdb
                                                                           /- 2. partbyattr                -       the data is partitioned by [ partitiontype ] and the column(s) assigned the parted attributed in sort.csv
                                                                           /-                                      at EOD the data will be merged from each partiton before being moved to hdb
                                                                           /- 3. partbyenum                -       the data is partitioned by [ partitiontype ] and a symbol column with parted attribution assigned in sort.csv
                                                                           /-                                      at EOD the data will be merged from each partiton before being moved to hdb
partwritemodes:`partbyattr`partbyenum;
enumcol:@[value;`enumcol;`sym];                                            /-symbol column to enumerate by. Only used with writedownmode: partbyenum.

mergemode:@[value;`mergemode;`part]; 				                       /-the partbyattr writdown mode can merge data from tenmporary storage to the hdb in three ways:
                                                                           /- 1. part                      -       the entire partition is merged to the hdb
                                                                           /- 2. col                       -       each column in the temporary partitions are merged individually
                                                                           /- 3. hybrid                    -       partitions merged by column or entire partittion based on byte limit

mergenumbytes:@[value;`mergenumbytes;500000000];                             /-default number of bytes for merge process

mergenumrows:@[value;`mergenumrows;100000];                                /-default number of rows for merge process
mergenumtab:@[value;`mergenumtab;`quote`trade!10000 50000];                /-specify number of rows per table for merge process

hdbtypes:@[value;`hdbtypes;`hdb];                                          /-list of hdb types to look for and call in hdb reload
rdbtypes:@[value;`rdbtypes;`rdb];                                          /-list of rdb types to look for and call in rdb reload
idbtypes:@[value;`idbtypes;`idb];                                          /-list of idb types to look for and call in idb reload
gatewaytypes:@[value;`gatewaytypes;`gateway];                              /-list of gateway types to inform at reload
tickerplanttypes:@[value;`tickerplanttypes;`tickerplant];                  /-list of tickerplant types to try and make a connection to
tpconnsleepintv:@[value;`tpconnsleepintv;10];                              /-number of seconds between attempts to connect to the tp
tpcheckcycles:@[value;`tpcheckcycles;0W];                                  /-number of attempts to connect to tp before process is killed

sorttypes:@[value;`sorttypes;`sort];                                       /-list of sort types to look for upon a sort
sortworkertypes:@[value;`sortworkertypes;`sortworker];                     /-list of sort types to look for upon a sort being called with worker process

subtabs:@[value;`subtabs;`];                                               /-list of tables to subscribe for
subsyms:@[value;`subsyms;`];                                               /-list of syms to subscription to
upd:@[value;`upd;{insert}];                                                /-value of the upd function

ignorelist:@[value;`ignorelist;`heartbeat`logmsg]                          /-list of tables to ignore
replay:@[value;`replay;1b];                                                /-replay the tickerplant log file
schema:@[value;`schema;1b];                                                /-retrieve schema from tickerplant
settimer:@[value;`settimer;0D00:00:10];                                    /-set timer interval for row check

reloadorder:@[value;`reloadorder;`hdb`rdb];                                /-order to reload hdbs, rdbs
sortcsv:@[value;`sortcsv;`:config/sort.csv];                               /-location of csv file
permitreload:@[value;`permitreload;1b];                                    /-enable reload of hdbs/rdbs

gc:@[value;`gc;1b];                                                        /-garbage collect at appropriate points (after each table save and after sorting data)

eodwaittime:@[value;`eodwaittime;0D00:00:10.000];                          /-length of time to wait for async callbacks to complete at eod

/ - settings for the common save code (see code/common/save.q)
.save.savedownmanipulation:@[value;`.save.savedownmanipulation;()!()];           /-a dict of table!function used to manipulate tables at EOD save
.save.postreplay:@[value;`.save.postreplay;{{[d;p] }}];                          /-post EOD function, invoked after all the tables have been written down

/ - end of default parameters

/ - define .z.pd in order to connect to any worker processes
.dotz.set[`.z.pd;{$[.z.K<3.3;
    `u#`int$();
    `u#exec w from .servers.getservers[`proctype;sortworkertypes;()!();1b;0b]]}]

/- fix any backslashes on windows
savedir:.os.pthq savedir;
hdbdir:.os.pthq hdbdir;

/- define the save and sort flags
saveenabled: any `save`saveandsort in mode;
sortenabled: any `sort`saveandsort in mode;

/ - log which modes are enabled
switch: string `off`on;
.lg.o[`savemode;"save mode is ",switch[saveenabled]];
.lg.o[`sortmode;"sort mode is ",switch[sortenabled]];

/ - check to ensure that the process can do one of save or sort
if[not any saveenabled,sortenabled; .lg.e[`init;"process mode not configured correctly.  Mode should be one of the following: save, sort or saveandsort"]];

/ - ensure process code is loaded, e.g. in sort process
.proc.loaddir getenv[`KDBCODE],"/wdb";

/- extract user defined row counts for merge process
mergemaxrows:{[tabname] mergenumrows^mergenumtab[tabname]}


/- function to return a list of tables that the wdb process has been configured to deal within
tablelist:{[] sortedlist:exec tablename from `bytes xdesc .wdb.tabsizes;
    (sortedlist union tables[`.]) except ignorelist}

/- function to upsert to specified directory
upserttopartition:{[dir;tablename;tabdata;pt;expttype;expt]
    .lg.o[`save;"saving ",(string tablename)," data to partition ",
        /- create directory location for selected partiton
        string directory:` sv .Q.par[dir;pt;tablename],
        /- replace random chracters in symbols with _
        (`$"_"^.Q.an .Q.an?"_" sv string
        /- convert to symbols and replace any null values with `NONE
        `NONE^ -1 _ `${@[x; where not ((type each x) in (10 -10h));string]} expt,(::)),`];
    /- upsert selected data matched on partition to specific directory
    .[
        upsert;
        (directory;r:?[tabdata;{(x;y;(),z)}[in;;]'[expttype;expt];0b;()]);
        {[e] .lg.e[`savetablesbypart;"Failed to save table to disk : ",e];'e}
    ];
    .lg.o[`track;"appending details to partsizes"];
    /-key in partsizes are directory to partition, need to drop training slash in directory key
    .merge.partsizes[first ` vs directory]+:(count r;-22!r);
    };

/- function to upsert to specified directory using enumerated extra partitioning
upserttopartitionenum:{[dir;tablename;tabdata;pt;expttype;expt]
    hdbsym:` sv hdbsettings[`hdbdir],`sym;
    /- enumerate current extra partition agains the hdb sym file
    i:get[hdbsym]?hdbsym?first expt;
    .lg.o[`save;"saving ",(string tablename)," data to partition ",
                /- create directory location for selected partiton
                string directory:` sv .Q.par[dir;pt;`$string i],tablename,`];
    /- upsert selected data matched on partition to specific directory
    .lg.o[`save;"directory: ",string directory];
    .[
     upsert;
     (directory;r:?[tabdata;{(x;y;(),z)}[in;;]'[expttype;expt];0b;()]);
     {[e] .lg.e[`savetablesbypartenum;"Failed to save table to disk : ",e];'e}
     ];
    .lg.o[`track;"appending details to partsizes"];
    /-key in partsizes are directory to partition, need to drop training slash in directory key
    .merge.partsizes[first ` vs directory]+:(count r;-22!r);
 };

savetablesbypart:{[dir;pt;forcesave;tablename]
    /- check row count and save if maxrows exceeded
    /- forcesave will write flush the data to disk irrespective of counts
    if[forcesave or maxrows[tablename] < arows: count value tablename;
        .lg.o[`rowcheck;"the ",(string tablename)," table consists of ", (string arows), " rows"];
        /- get additional partition(s) defined by parted attribute in sort.csv
        extrapartitiontype:.merge.getextrapartitiontype[tablename];
        /- check each partition type actually is a column in the selected table
        .merge.checkpartitiontype[tablename;extrapartitiontype];
        /- get list of distinct combiniations for partition directories
        extrapartitions:.merge.getextrapartitions[tablename;extrapartitiontype];
        /- enumerate data to be upserted
        enumdata:.Q.en[hdbsettings[`hdbdir];0!.save.manipulate[tablename;`. tablename]];
        .lg.o[`save;"enumerated ",(string tablename)," table"];
        /- upsert data to specific partition directory
        upserttopartition[dir;tablename;enumdata;pt;extrapartitiontype] each extrapartitions;
                /- empty the table
        .lg.o[`delete;"deleting ",(string tablename)," data from in-memory table"];
        @[`.;tablename;0#];
        /- run a garbage collection (if enabled)
        if[gc;.gc.run[]];
    ];
    };

savetablesbypartenum:{[dir;pt;forcesave;tablename]
    savetablesbypartenumcol[dir;pt;forcesave;tablename;enumcol];
 };

savetablesbypartenumcol:{[dir;pt;forcesave;tablename;extrapartitiontype]
    /- check row count and save if maxrows exceeded
    /- forcesave will write flush the data to disk irrespective of counts
    if[forcesave or maxrows[tablename] < arows: count value tablename;
       .lg.o[`rowcheck;"the ",(string tablename)," table consists of ", (string arows), " rows"];
       /- check if provided symbol column extrapartitiontype indeed has a symbol type in table
       .merge.checksymboltype[tablename;extrapartitiontype];
       /- get list of distinct combinations for partition directories
       extrapartitions:.merge.getextrapartitions[tablename;extrapartitiontype];
       /- enumerate data to be upserted
       enumdata:.Q.en[hdbsettings[`hdbdir];0!.save.manipulate[tablename;`. tablename]];
       .lg.o[`save;"enumerated ",(string tablename)," table"];
       /- upsert data to specific partition directory
       upserttopartitionenum[dir;tablename;enumdata;pt;extrapartitiontype] each extrapartitions;
       /- empty the table
       .lg.o[`delete;"deleting ",(string tablename)," data from in-memory table"];
       @[`.;tablename;0#];
       /- run a garbage collection (if enabled)
       if[gc;.gc.run[]];
      ];
 };

/- modify savetable if parbyattr writedown option selected
savetables:$[writedownmode~`partbyattr;savetablesbypart;writedownmode~`partbyenum;savetablesbypartenum;savetables];

savetodisk:{[]
    savetables[savedir;getpartition[];0b;] each tablelist[];
    /- we have to let the idbs know of the changes in the wdbhdb. using filldb[] to make sure it is a db with all the tables
    if[writedownmode in `partbyenum;filldb[];notifyidbs[0b]]};

/- send an intraday reload message to idbs:
notifyidbs:{[islogging]
    ws:exec w from .servers.getservers[`proctype;`idb;()!();1b;0b];
    if[islogging;.lg.o[`reload;"found ",(string count ws)," idb(s) to trigger reload"]];
    /-send async message along each handle
    {neg[x](`.idb.intradayreload;.wdb.currentpartition)} each ws;
 };

/- eod - flush remaining data to disk
endofday:{[pt;processdata]
    .lg.o[`eod;"end of day message received - ",spt:string pt];
        /- set what type of merge method to be used
        mergemethod:.wdb.mergemode;
    /- create a dictionary of tables and merge limits, byte or row count limit depending on settings
    .lg.o[`merge;"merging partitons by ",$[.merge.mergebybytelimit;"byte estimate";"row count"]," limit"];
    mergelimits:(tablelist[],())!($[.merge.mergebybytelimit;{(count x)#mergenumbytes};{[x] mergenumrows^mergemaxrows[x]}]tablelist[]),();
    tablist:tablelist[]!{0#value x} each tablelist[];
    / Need to download sym file to scratch directory if this is Finspace application
        if[.finspace.enabled;
                        .lg.o[`createchangeset;"downloading sym file to scratch directory for ",.finspace.database];
                        .aws.get_latest_sym_file[.finspace.database;getenv[`KDBSCRATCH]];
            ];
    / - if save mode is enabled then flush all data to disk
    if[saveenabled;
        endofdaysave[savedir;pt];
        / - if sort mode enable call endofdaysort within the process,else inform the sort and reload process to do it
        $[sortenabled;endofdaysort;informsortandreload] . (savedir;pt;tablist;writedownmode;mergelimits;hdbsettings;mergemethod);
        if[.finspace.enabled;changeset:.finspace.createchangeset[.finspace.database]];
        ];
    .lg.o[`eod;"deleting data from ",$[r:writedownmode in partwritemodes;"partsizes";"tabsizes"]];
    $[r;@[`.merge;`partsizes;0#];@[`.wdb;`tabsizes;0#]];
    /-notify all finspace hdbs
    if[.finspace.enabled;.finspace.notifyhdb[;changeset] each .finspace.hdbclusters];
    .wdb.currentpartition:pt+1;
    /- in case of partbyenum writedown mode we want to initialise the new partition under 0 with all the table schemas
    /- then notify idb processes of the new db
    if[writedownmode in `partbyenum;
       .lg.o[`eod;"initialising wdbhdb for partition: ",string[.wdb.currentpartition],"/0"];
       initmissingtables[`0];
       .lg.o[`eod;"notifying idbs for newly created partition"];
       notifyidbs[1b]];
    .lg.o[`eod;"end of day is now complete"];
    if[.finspace.enabled;.os.hdeldir[getenv[`KDBSCRATCH];0b]];
    };

endofdaysave:{[dir;pt]
    /- save remaining table rows to disk
    .lg.o[`save;"saving the ",(", " sv string tl:tablelist[],())," table(s) to disk"];
    savetables[dir;pt;1b;] each tl;
    .lg.o[`savefinish;"finished saving data to disk"];
    };

/- add entries to table of callbacks. if timeout has expired or d now contains all expected rows then it releases each waiting process
handler:{
    /-insert process reload outcome into .wdb.reloadsummary
        .wdb.reloadsummary[.z.w]:x;
        /-log result of reload in wdb out log
        .lg.o[`reloadproc;"the ", string[.wdb.reloadsummary[.z.w]`process]," process ", string[.wdb.reloadsummary[.z.w]`result]];
        if[(.proc.cp[]>.wdb.timeouttime) or (count[.wdb.reloadsummary]=.wdb.countreload);
                .lg.o[`handler;"releasing processes"];
                .lg.o[`reload;string[count select from .wdb.reloadsummary where status=1]," out of ", string[count .wdb.reloadsummary]," processes successfully reloaded"];
                .wdb.flushend[];
        /-delete contents from .wdb.reloadsummary when reloads completed
                delete from `.wdb.reloadsummary];
        };

/- evaluate contents of d dictionary asynchronously
/- notify the gateway that we are done
flushend:{
    if[not @[value;`.wdb.reloadcomplete;0b];
     @[{neg[x]"";neg[x][]};;()] each key reloadsummary;
     informgateway(`reloadend;`);
     .lg.o[`sort;"end of day sort is now complete"];
     .wdb.reloadcomplete:1b];
    /- run a garbage collection (if enabled)
    if[gc;.gc.run[]];
    };

/- initialise reloadsummary, keyed table to track status of local reloads
reloadsummary:([handle:`int$()]process:`symbol$();status:`boolean$();result:`symbol$());

doreload:{[pt]
    .wdb.reloadcomplete:0b;
    /-inform gateway of reload start
    informgateway(`reloadstart;`);
    getprocs[;pt] each reloadorder;
    if[eodwaittime>0;
        .timer.one[.wdb.timeouttime:.proc.cp[]+.wdb.eodwaittime;(value;".wdb.flushend[]");"release all hdbs and rdbs as timer has expired";0b];
    ];
    };

// set .z.zd to control how data gets compressed
setcompression:{[compression] if[3=count compression;
                 .lg.o[`compression;$[compression~16 0 0;"resetting";"setting"]," compression level to (",(";" sv string compression),")"];
                 .dotz.set[`.z.zd;compression]
                ]}
resetcompression:{setcompression 16 0 0 }

//check if the hdb directory contains current partition
//if yes check if patition is empty and if it is not see if any of the tables exist in both the 
//temporary parition and the hdb partition. If there is a clash abort operation otherwise copy 
//each table to the hdb partition
movetohdb:{[dw;hw;pt]
  $[not(`$string pt)in key hsym`$-10 _ hw;
     .[.os.ren;(dw;hw);{.lg.e[`mvtohdb;"Failed to move data from wdb ",x," to hdb directory ",y," : ",z]}[dw;hw]];
      not any a[dw]in(a:{key hsym`$x}) hw;
      [{[y;x]
        $[not(b:`$last"/"vs x)in key y;
          [.[.os.ren;(x;y);{[x;y;e].lg.e[`mvtohdb;"Table ",string[x]," has failed to copy to ",string[y]," with error: ",e]}[b;y;]];
           .lg.o[`mvtohdb;"Table ",string[b]," has been successfully moved to ",string[y]]];
          .lg.e[`mvtohdb;"Table ",string[b]," was skipped because it already exists in ",string[y]]];
        }[hsym`$hw]'[dw,/:"/",/:string key hsym`$dw];
        if[0=count key hsym`$dw;@[.os.deldir;dw;{[x;y].lg.e[`mvtohdb;"Failed to delete folder ",x," with error: ",y]}[dw]]]];
     .lg.e[`mvtohdb;raze"Table(s) ",string[(key hsym`$hw)inter(key hsym`$dw)]," is present in both location. Operation will be aborted to avoid corrupting the hdb"]]
 }

reloadsymfile:{[symfilepath]
  .lg.o[`sort; "reloading the sym file from: ",string symfilepath];
  @[load; symfilepath; {.lg.e[`sort;"failed to reload sym file: ",x]}]
 }

endofdaysortdate:{[dir;pt;tablist;hdbsettings]
  /-sort permitted tables in database
  /- sort the table and garbage collect (if enabled)
  .lg.o[`sort;"starting to sort data"];
  /- .z.pd funciton in finspace will cause an error. Add in this check to skip over the use of .z.pd. This should be temporary and will be removed when issue resolved by AWS.
  tempfix1:$[.finspace.enabled;0b;count[.z.pd[]]];
  $[tempfix1&0>system"s";
    [.lg.o[`sort;"sorting on worker sort", string .z.p];
     {(neg x)(`.wdb.reloadsymfile;y);(neg x)(::)}[;.Q.dd[hdbsettings `hdbdir;`sym]] each .z.pd[];
     {[x;compression] setcompression compression;.sort.sorttab x;if[gc;.gc.run[]]}[;hdbsettings`compression] peach tablist,'.Q.par[dir;pt;] each tablist];
    [.lg.o[`sort;"sorting on main sort"];
     reloadsymfile[.Q.dd[hdbsettings `hdbdir;`sym]];
    {[x] .sort.sorttab[x];if[gc;.gc.run[]]} each tablist,'.Q.par[dir;pt;] each tablist]];
  .lg.o[`sort;"finished sorting data"];

  /-move data into hdb
  .lg.o[`mvtohdb;"Moving partition from the temp wdb ",(dw:.os.pth -1 _ string .Q.par[dir;pt;`])," directory to the hdb directory ",hw:.os.pth -1 _ string .Q.par[hdbsettings[`hdbdir];pt;`]];
  .lg.o[`mvtohdb;"Attempting to move ",(", "sv string key hsym`$dw)," from ",dw," to ",hw];
  .[movetohdb;(dw;hw;pt);{.lg.e[`mvtohdb;"Function movetohdb failed with error: ",x]}];

  /-call the posteod function
  .save.postreplay[hdbsettings[`hdbdir];pt];
  if[permitreload;
    doreload[pt];
    ];
  };

merge:{[dir;pt;tableinfo;mergelimits;hdbsettings;mergemethod;writedownmode]
  setcompression[hdbsettings[`compression]];
  /- get tablename
  tabname:tableinfo[0];
  /- get list of partition directories for specified table - partbyattr and partbyenum use different folder structure
  partdirs:$[writedownmode in `partbyenum;
             p where 0<count each key each p:` sv' ((-1_` vs p),/:key p:.Q.par[hsym dir;pt;`]),\: tabname;
             ` sv' tabledir,/:key tabledir:.Q.par[hsym dir;pt;tabname]];
  /- we only really have to merge those partitions where we have received some updates, otherwise table is empty
  partdirs:partdirs inter exec ptdir from .merge.partsizes;
  /- get directory destination for permanent storage
  dest:.Q.par[hdbsettings[`hdbdir];pt;tabname];
  .lg.o[`merge;"merging ",string[tabname]," to ",string dest];
  /- exit function if no subdirectories are found
  $[0=count partdirs;
    [.lg.w[`merge;"no records found for ",(string tabname),", merging empty table"];
     (` sv dest,`) set @[.Q.en[hdbsettings[`hdbdir];tableinfo[1]];.merge.getextrapartitiontype[tabname];`p#];
    ];
   /-if there are partitions to merge - merge with correct function
   [.lg.o[`merge;"mergemethod: ",string mergemethod];
    $[mergemethod~`part;
      [dest: ` sv dest,`;
       /-get chunks to partitions to merge in batch
       partchunks:.merge.getpartchunks[partdirs;mergelimits[tabname]];
       .merge.mergebypart[tabname;dest]'[partchunks];
      ];
    mergemethod~`col;
      [.merge.mergebycol[tableinfo;dest]'[partdirs];
       /-merging data column at a time means no .d file is created so need to create one after function executed
       .lg.o[`merge;"creating file ", (string ` sv dest,`.d)];
       (` sv dest,`.d) set cols tableinfo[1];
      ];
       .merge.mergehybrid[tableinfo;dest;partdirs;mergelimits[tabname]]
    ];
    .lg.o[`merge;"removing segments ", (", " sv string[partdirs])];
    $[writedownmode in `partbyenum;
      removetablefromenumdir each partdirs;
      .os.deldir .os.pth[[string[tabledir]]]
     ];
    /- set the attributes
    .lg.o[`merge;"setting attributes"];
    @[dest;;`p#] each .merge.getextrapartitiontype[tabname];
    .lg.o[`merge;string[tabname]," merge complete"];
   ]
  ]
 };

/- enumerated partitions have a directory structure of: db/<partition>/<enumerated extra partition>/<table>
/- this function deletes <table> folder or the whole <enumerated extra partition> if it only has one element
removetablefromenumdir:{[partdir]
    enumdir:` sv -1_` vs partdir;
    .os.deldir .os.pth string $[1=count key enumdir;enumdir;partdir];
  };

endofdaymerge:{[dir;pt;tablist;mergelimits;hdbsettings;mergemethod;writedownmode]
  /- merge data from partitons
  /- .z.pd funciton in finspace will cause an error. Add in this check to skip over the use of .z.pd. This should be temporary and will be removed when issue resolved by AWS.
  tempfix2:$[.finspace.enabled;0b;(0 < count .z.pd[])];
  $[tempfix2 and ((system "s")<0);
    [.lg.o[`merge;"merging on worker"];
     {(neg x)(`.wdb.reloadsymfile;y);(neg x)(::)}[;.Q.dd[hdbsettings `hdbdir;`sym]] each .z.pd[];
     /-upsert .merge.partsize data to sort workers, only needed for part and hybrid method
     if[(mergemode~`hybrid)or(mergemode~`part);
       {(neg x)(upsert;`.merge.partsizes;y);(neg x)(::)}[;.merge.partsizes] each .z.pd[];
       ];
     merge[dir;pt;;mergelimits;hdbsettings;mergemethod;writedownmode] peach flip (key tablist;value tablist);
     /-clear out in memory table, .merge.partsizes, and call sort worker processes to do the same
     .lg.o[`eod;"Delete from partsizes"];
     delete from `.merge.partsizes;
     {(neg x)({.lg.o[`eod;"Delete from partsizes"];
               delete from `.merge.partsizes;
               /- run a garbage collection if enabled
               if[gc;.gc.run[]]};`);(neg x)(::)} each .z.pd[];
    ];
    [.lg.o[`merge;"merging on main"];
     reloadsymfile[.Q.dd[hdbsettings `hdbdir;`sym]];
     merge[dir;pt;;mergelimits;hdbsettings;mergemethod;writedownmode] each flip (key tablist;value tablist);
     .lg.o[`eod;"Delete from partsizes"];
     delete from `.merge.partsizes;
    ]
   ];
  /- if path exists, delete it
  if[not () ~ key savedir;
    .lg.o[`merge;"deleting temp storage directory"];
    .os.deldir .os.pth[string[` sv savedir,`$string[pt]]];
    ];
  /-call the posteod function
  .save.postreplay[hdbsettings[`hdbdir];pt];
  $[permitreload;
    doreload[pt];
    if[gc;.gc.run[]];
    ];
  };

/- end of day sort [depends on writedown mode]
endofdaysort:{[dir;pt;tablist;writedownmode;mergelimits;hdbsettings;mergemethod]
    /- set compression level (.z.zd)
    setcompression[hdbsettings[`compression]];
    $[writedownmode in partwritemodes;
        endofdaymerge[dir;pt;tablist;mergelimits;hdbsettings;mergemethod;writedownmode];
        endofdaysortdate[dir;pt;key tablist;hdbsettings]
    ];
    /- reset compression level (.z.zd)
    resetcompression[16 0 0]
    };

/-function to send reload message to rdbs/hdbs
reloadproc:{[h;d;ptype]
        /-count of processes to be reloaded
        .wdb.countreload:count[raze .servers.getservers[`proctype;;()!();1b;0b]each reloadorder];
        /-defining lambdas to be in asynchronously calling processes to reload
        /-async call back function executed when eodwaittime>0
        sendfunc:{[x;y;ptype].[{neg[y]@x};(x;y);{[ptype;x].lg.e[`reloadproc;"failed to reload the ",string[ptype]];'x}[ptype]]};
        /-reload function sent to processes by sendfunc in order to call process to reload. If process fail to reload log error
        /-and call .wdb.handler with failed reload message. If reload is successful call .wdb.handler with successful reload message.
        reloadfunc:{[d;ptype] r:@[{(1b;`. `reload x)};d;{.lg.e[`reloadproc;"failed to reload from .wdb.reloadproc call. The error was : ",x];(0b;x)}];
                (neg .z.w)(`.wdb.handler;(ptype;first r;$[first r;`$"reloaded successfully";`$"reload failed with error ",last r]));(neg .z.w)[]};
        /-reload function to be executed if eodwaitime = 0 - sync message processes to reload and log if reload was successful or failed
        syncreloadfunc:{[h;d;ptype] r:@[h;({(1b;`reload x)};d);{[ptype;e] .lg.e[`reloadproc;"failed to reload the ",string[ptype],". The error was : ",e];(0b;e)}[ptype]];
                .lg.o[`reloadproc;"the ", string[ptype]," ", $[first r; "successfully reloaded"; "failed to reload with error ",last r]]};
        .lg.o[`reloadproc;"sending reload call to ", string[ptype]];
        $[eodwaittime>0;
                 sendfunc[(reloadfunc;d;ptype);h;ptype];
         syncreloadfunc[h;d;ptype]
        ];
        }

/-function to discover rdbs/hdbs and attempt to reconnect	
getprocs:{[x;y]
    a:exec (w!x) from .servers.getservers[`proctype;x;()!();1b;0b];
    /-exit if no valid handle
    if[0=count a; .lg.e[`connection;"no connection to the ",(string x)," could be established... failed to reload ",string x];:()];
    .lg.o[`connection;"connection to the ", (string x)," has been located"];
    /-send message along each handle a
    reloadproc[;y;value a] each key a;
    }

/-function to send messages to gateway	
informgateway:{[message]
    .lg.o[`informgateway;"sending message to gateway(s)"];
    $[count gateways:.servers.getservers[`proctype;gatewaytypes;()!();1b;0b];
       [
           {.[@;(y;x);{.lg.e[`informgateway;"unable to run command on gateway"];'x}]}[message;] each exec w from gateways;
           .lg.o[`informgateway;"the message - ",(.Q.s message), " was sent to the gateways"]
       ];
       .lg.e[`informgateway;"can't connect to the gateway - no gateway detected"]]
    }

/- function to call that will cause sort & reload process to sort data and reload rdb and hdbs
informsortandreload:{[dir;pt;tablist;writedownmode;mergelimits;hdbsettings;mergemethod]
        .lg.o[`informsortandreload;"attempting to contact sort process to initiate data ",$[writedownmode~`default;"sort";"merge"]];
    $[count sortprocs:.servers.getservers[`proctype;sorttypes;()!();1b;0b];
        [if[(mergemode~`hybrid)or(mergemode~`part);
            // for part and hybrid method sort procs need access to partsizes table data - upsert data tp sort procs
            {(neg x)(upsert;`.merge.partsizes;y);(neg x)(::)}[;.merge.partsizes] each exec w from sortprocs;
           ];
         {.[{neg[y]@x;neg[y][]};(x;y);{.lg.e[`informsortandreload;"unable to run command on sort and reload process"];'x}]}[(`.wdb.endofdaysort;dir;pt;tablist;writedownmode;mergelimits;hdbsettings;mergemethod);] each exec w from sortprocs;
        ];
        [.lg.e[`informsortandreload;"can't connect to the sortandreload - no sortandreload process detected"];
         // try to run the sort locally
         endofdaysort[dir;pt;tablist;writedownmode;mergelimits;hdbsettings;mergemethod]]];
    };

/-function to set the timer for the save to disk function	
starttimer:{[]
    $[@[value;`.timer.enabled;0b];
        [.lg.o[`init;"adding the wdb save to disk function to the timer"];
        /-add .wdb.savetodisk function to TorQ timer
        .timer.repeat[.proc.cp[];0Wp;settimer;(`.wdb.savetodisk;`);"save wdb data to disk"];
        .lg.o[`init;"the timer has been set to ", string settimer]];
        /-if timer not enabled, prompt user to enable it
        .lg.e[`init;"the timer has not been enabled - please enable the timer to run the wdb"]];
    }

/-function to subscribe to tickerplant
subscribe:{[]
    s:.sub.getsubscriptionhandles[tickerplanttypes;();()!()];
    if[count s;
        .lg.o[`subscribe;"tickerplant found - subscribing to ", string (subproc: first s)`procname];
        /- return the tables subscribed to and the tickerplant log date
        subto:.sub.subscribe[subtabs;subsyms;schema;replay;subproc];
        /- check the tp logdate against the current date and correct if necessary
        fixpartition[subto];
        /- add missing tables to partitions in case an intraday process wants to connect. Only applicable for partbyenum writedown mode
        if[.wdb.writedownmode ~ `partbyenum;initmissingtables[`0]];];
 }

/- function to rectify data written to wrong partition
fixpartition:{[subto]
    /- check if the tp logdate matches current date
    if[not (tplogdate:subto[`tplogdate])~orig:.wdb.currentpartition;
        .lg.o[`fixpartition;"Current partiton date does not match the ticker plant log date"];
        /- set the current partiton date to the log date
        .wdb.currentpartition:tplogdate;
        /- move the data that has been written to correct partition
        pth1:.os.pth[-1 _ string .Q.par[savedir;orig;`]];
        pth2:.os.pth[-1 _ string .Q.par[savedir;tplogdate;`]];
        if[not ()~key hsym `$.os.pthq pth1;
          /- delete any data in the current partiton directory
              clearwdbdata[];
          .lg.o[`fixpartition;"Moving data from partition ",(.os.pthq pth1) ," to partition ",.os.pthq pth2];
          .[.os.ren;(pth1;pth2);{.lg.e[`fixpartition;"Failed to move data from wdb partition ",x," to wdb partition ",y," : ",z]}[pth1;pth2]]];
        ];
    }

/- for writedown mode partbyenum we make sure that partition 0 has all the tables.
/- In that case we can use .Q.chk later to fill the db making it useable for intraday processes
initmissingtables:{[part]
    inittable[part;] each tablelist[];
    filldb[];
 }

filldb:{[]
    /- for all enumerated partitions we want to make sure that all tables are present
    .Q.chk[.Q.par[savedir; .wdb.currentpartition; `]];
 }

/- initialises table t in db with its schema in part
inittable:{[part;t]
    if[not -11h ~ type part;part:`$string part];
    tabledir:` sv .Q.par[savedir;.wdb.currentpartition;part],t,`;
    if[() ~ key tabledir;tabledir set .Q.en[hdbdir;0#value t]];
 }

/- will check on each upd to determine where data should be flushed to disk (if max row limit has been exceeded)
replayupd:{[f;t;d]
    /- execute the supplied function
        f . (t;d);
    /- if the data count is greater than the threshold, then flush data to disk
    if[(rpc:count[value t]) > lmt:maxrows[t];
        .lg.o[`replayupd;"row limit (",string[lmt],") exceeded for ",string[t],". Table count is : ",string[rpc],". Flushing table to disk..."];
        savetables[savedir;getpartition[];0b;t]]
    }[upd];

/ - if there is data in the wdb directory for the partition, if there is remove it before replay
/ - is only for wdb processes that are saving data to disk
clearwdbdata:{[]
    $[saveenabled and not () ~ key wdbpart:.Q.par[savedir;getpartition[];`];
        [.lg.o[`deletewdbdata;"removing wdb data (",(delstrg:1_string wdbpart),") prior to log replay"];
        @[.os.deldir;delstrg;{[e] .lg.e[`deletewdbdata;"Failed to delete existing wdb data.  Error was : ",e];'e }];
        .lg.o[`deletewdbdata;"finished removing wdb data prior to log replay"];
        ];
        .lg.o[`deletewdbdata;"no directory found at ",1_string wdbpart]
    ];
    };

/ - function to check that the tickerplant is connected and subscription has been setup
notpconnected:{[]
    0 = count select from .sub.SUBSCRIPTIONS where proctype in .wdb.tickerplanttypes, active}

getsortparams:{[]
    /- get the attributes csv file
    /-even if running with a sort process should read this file to cope with backups
    .sort.getsortcsv[.wdb.sortcsv];
    /- check the sort.csv for parted attributes `p if the writedownmode `partbyattr or `partbyenum is selected
    /- if each table does not have at least one `p attribute the process will exit
    if[writedownmode in partwritemodes;

        /- check that default table is defined
        if[not count exec distinct tabname from .sort.params where tabname=`default,att=`p,sort=1b;
            .lg.e[`init;"default table not defined in sort.csv with at least one `p attribute and sort=1b"];
        ];
        .lg.o[`init;"default table defined in sort.csv and with at least one `p attribute and sort=1b"];

        /- check for `p attributes
        if[count notparted:distinct .sort.params[`tabname] except distinct exec tabname from .sort.params where att in `p;
            .lg.e[`init;"parted attribute p not set at least once in sort.csv for table(s): ", ", " sv string notparted];
        ];
        .lg.o[`init;"parted attribute p set at least once for each table in sort.csv"];
    ];
    };

/- notifying the connecting idbs that they can trigger their setup(since wdb has created the folder/db they will load)
.wdb.setupidbs:{[]
    .lg.o[`init;"sending message to idbs with db location and current partition"];
    ws:exec w from .servers.getservers[`proctype;`idb;()!();1b;0b];
    .lg.o[`init;"found ",string[count ws]," idb(s). Initiating setup on them..."];
    /-send async message along each handle
    {neg[x](`.idb.setup;savedir;.wdb.currentpartition)} each ws;
 };

\d .

/- get the sort attributes for each table
.wdb.getsortparams[];


/- make sure to request connections for all the correct types
.servers.CONNECTIONS:(distinct .servers.CONNECTIONS,.wdb.hdbtypes,.wdb.rdbtypes,.wdb.gatewaytypes,.wdb.tickerplanttypes,.wdb.sorttypes,.wdb.sortworkertypes,.wdb.idbtypes) except `

/-  adds endofday  function to top level namespace
endofday: .wdb.endofday;
/- setting the upd and .u.end functions as the .wdb versions
.u.end:{[pt]
    .wdb.endofday[.wdb.getpartition[];()!()];
    }

/- set the replay upd 
.lg.o[`init;"setting the log replay upd function"];
upd:.wdb.replayupd;
/ - clear any wdb data in the current partition
.wdb.clearwdbdata[];
/- initialise the wdb process
.wdb.startup[];
/- setup db folder and current partition for possible connecting idbs.
.wdb.setupidbs[];
/ - start the timer
if[.wdb.saveenabled;.wdb.starttimer[]];

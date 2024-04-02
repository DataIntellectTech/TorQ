\d .wdb

/-Required variables for savetables function
compression:@[value;`compression;()];                                      /-specify the compress level, empty list if no required
savedir:@[value;`savedir;`:temphdb];                                       /-location to save wdb data
hdbdir:@[value;`hdbdir;`:hdb];                                             /-move wdb database to different location

hdbsettings:(`compression`hdbdir)!(compression;hdbdir);
numrows:@[value;`numrows;100000];                                          /-default number of rows
numtab:@[value;`numtab;`quote`trade!10000 50000];                          /-specify number of rows per table
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not


maxrows:{[tabname] numrows^numtab[tabname]};                               /- extract user defined row counts

partitiontype:@[value;`partitiontype;`date];                               /-set type of partition (defaults to `date)


getpartition:@[value;`getpartition;                                        /-function to determine the partition value
        {{@[value;`.wdb.currentpartition;
				(`date^partitiontype)$(.z.D,.z.d)gmttime]}}];

currentpartition:.wdb.getpartition[];                                      /- Initialise current partiton

tabsizes:([tablename:`symbol$()] rowcount:`long$(); bytes:`long$());       /- keyed table to track the size of tables on disk

savetables:{[dir;pt;forcesave;tabname]
        /- check row count
        /- forcesave will write flush the data to disk irrespective of counts
        if[forcesave or maxrows[tabname] < arows: count value tabname;
        .lg.o[`rowcheck;"the ",(string tabname)," table consists of ", (string arows), " rows"];
        /- upsert data to partition
        .lg.o[`save;"saving ",(string tabname)," data to partition ", string pt];
        .[
                upsert;
                (` sv .Q.par[dir;pt;tabname],`;.Q.en[hdbsettings[`hdbdir];r:0!.save.manipulate[tabname;`. tabname]]);
                {[e] .lg.e[`savetables;"Failed to save table to disk : ",e];'e}
        ];
        /- make addition to tabsizes
        .lg.o[`track;"appending table details to tabsizes"];
	.wdb.tabsizes+:([tablename:enlist tabname]rowcount:enlist arows;bytes:enlist -22!r);
        /- empty the table
        .lg.o[`delete;"deleting ",(string tabname)," data from in-memory table"];
        @[`.;tabname;0#];
        /- run a garbage collection (if enabled)
        if[gc;.gc.run[]];
	]};

endofdaymerge:{[dir;pt;tablist;mergelimits;hdbsettings;mergemethod]
  /- merge data from partitons
  $[(0 < count .z.pd[]) and ((system "s")<0);
    [.lg.o[`merge;"merging on worker"];
     {(neg x)(`.wdb.reloadsymfile;y);(neg x)(::)}[;.Q.dd[hdbsettings `hdbdir;`sym]] each .z.pd[];
     /-upsert .merge.partsize data to sort workers, only needed for part and hybrid method
     if[(mergemode~`hybrid)or(mergemode~`part);
       {(neg x)(upsert;`.merge.partsizes;y);(neg x)(::)}[;.merge.partsizes] each .z.pd[];
       ];
     merge[dir;pt;;mergelimits;hdbsettings;mergemethod] peach flip (key tablist;value tablist);
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
     merge[dir;pt;;mergelimits;hdbsettings;mergemethod] each flip (key tablist;value tablist);
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
  $[count[.z.pd[]]&0>system"s";
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

\d .
/-endofperiod function
endofperiod:{[currp;nextp;data] .lg.o[`endofperiod;"Received endofperiod. currentperiod, nextperiod and data are ",(string currp),", ", (string nextp),", ", .Q.s1 data]};

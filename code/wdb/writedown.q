\d .wdb

compression:@[value;`compression;()];                                      /-specify the compress level, empty list if no required
savedir:@[value;`savedir;`:temphdb];                                       /-location to save wdb data
hdbdir:@[value;`hdbdir;`:hdb];                                             /-move wdb database to different location

hdbsettings:(`compression`hdbdir)!(compression;hdbdir);
numrows:@[value;`numrows;100000];                                          /-default number of rows
numtab:@[value;`numtab;`quote`trade!10000 50000];                          /-specify number of rows per table
gmttime:@[value;`gmttime;1b];                                              /-define whether the process is on gmttime or not
/- extract user defined row counts
maxrows:{[tabname] numrows^numtab[tabname]};
partitiontype:@[value;`partitiontype;`date];                                /-set type of partition (defaults to `date)
/-function to determine the partition value
getpartition:@[value;`getpartition;
        {{@[value;`.wdb.currentpartition;
				(`date^partitiontype)$(.z.D,.z.d)gmttime]}}];

/- extract user defined row counts	
maxrows:{[tabname] numrows^numtab[tabname]}

currentpartition:.wdb.getpartition[];

tabsizes:([tablename:`symbol$()] rowcount:`long$(); bytes:`long$());

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

\d .
/-endofperiod function
endofperiod:{[currp;nextp;data] .lg.o[`endofperiod;"Received endofperiod. currentperiod, nextperiod and data are ",(string currp),", ", (string nextp),", ", .Q.s1 data]};

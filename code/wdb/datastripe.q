\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values

td:hsym `$getenv`KDBTAIL

\d .

.wdb.datastripeendofperiod:{[currp;nextp;data]
    .lg.o[`reload;"reload command has been called remotely"];
    
    // remove periods of data from tables
    t:tables[`.] except .wdb.ignorelist;
    lasttime:currp-.ds.periodstokeep*(nextp-currp);
    tabs:{![x;enlist (<;y;z);0b;0#`]}'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];
    };


initdatastripe:{
	// update endofday and endofperiod functions
    //endofday::endofday;
    endofperiod::.wdb.datastripeendofperiod;
    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

\d .ds

upserttopartitionnoexpt:{[dir;tablename;tabdata;pt]
  .lg.o[`save;"saving ",(string tablename)," data to partition ",
	/- create directory location for selected partition
	string directory:` sv .Q.par[dir;pt;tablename],`];
  /- upsert select data matched on partition to specific directory
  .[upsert;
    (directory;tabdata);
    {[e] .lg.e[`savetablesbypart;"Failed to save table to disk : ",e];'e}
  ];
  }

savetablesbysym:{[dir;extrapartitions;tablename;sym;extrapartitiontype;nextp]
        /- enumerate data to be upserted
        enumdata:.Q.en[dir;0!?[[`.]tablename;((<;`time;`nextp);(=;`sym;enlist sym));0b;()]];
        /- get partition subdirectory
        partitiondir:`$raze "partition.",string[?[[`.]`access;((=;`table;enlist tablename);(=;`keycol;enlist sym));();`int]];
        /- upsert data to specific partition directory
        $[extrapartitions~sym;
	  upserttopartitionnoexpt[dir;tablename;enumdata;partitiondir];
	  .wdb.upserttopartition[dir;tablename;enumdata;partitiondir;extrapartitiontype]each extrapartitions];
        };


savetablesoverperiod:{[dir;pt;tablename;nextp]
	/- get additional partition(s) defined by parted attribute in sort.csv
	extrapartitiontype:.merge.getextrapartitiontype[tablename];
	/- check each partition type actually is a column in the selected table
	.merge.checkpartitiontype[tablename;extrapartitiontype];
	/- get list of distinct combinations for partition directories
	extrapartitions:.merge.getextrapartitions[tablename;extrapartitiontype];
	/- check that extra partition type is different to tablecol in access table
	$[extrapartitiontype ~ raze first exec tablecol from [`.]`access where table=tablename;
	  partitionlist:extrapartitions,'extrapartitions;
	  partitionlist:extrapartitions cross value each ?[[`.]`access;enlist (=;`table;enlist tablename);1b;enlist[`keycol]!enlist `keycol]];
	/- save table by sym	
	.[savetablesbysym[dir;;tablename;;extrapartitiontype;nextp];]each partitionlist;
	/- delete data from specified period
	.[{![x;enlist(<;`time;y);0b;0#`]};(tablename;nextp)];
	/- run a garbage collection (if enabled)
	.gc.run[];
	};

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

upserttopartition:{[dir;tablename;keycol;enumdata;nextp]
	/- get unique sym from table
	s:first raze value'[?[enumdata;();1b;enlist[keycol]!enlist keycol]];
	/- get process specific taildir location
	dir:` sv dir,.proc.procname,`;
	/- get symbol enumeration
	partitionint:`$string (where s=value [`.]`sym)0;
	.lg.o[`save;"saving ",string[tablename]," data to partition ",
		/- create directory location for selected partition
		string directory:` sv .Q.par[dir;partitionint;tablename],`];
	/- upsert select data matched on partition to specific directory
	.[upsert;
	  (directory;enumdata);
	  {[e] .lg.e[`upserttopartition;"Failed to save table to disk : ",e];'e}
	];
	};	

savetablesoverperiod:{[dir;tablename;nextp]
	/- function to get keycol for table from access table
	keycol:.ds.tablekeycols[tablename];
	/- get distint values to partition table on
	partitionlist:raze value each ?[[`.]tablename;();1b;enlist[keycol]!enlist keycol];
	/- enumerate table to be upserted and get each table by sym
	enumdata:{[dir;tablename;keycol;nextp;s] .Q.en[dir;0!?[[`.]tablename;((<;`time;nextp);(=;keycol;enlist s));0b;()]]}[dir;tablename;keycol;nextp]'[partitionlist];
	/-upsert table to partition
	upserttopartition[dir;tablename;keycol;;nextp] each enumdata;
	/- delete data from last period
	.[{![[`.]x;enlist(<;`time;y);0b;0#`]};(tablename;nextp)];
	/- run a garbage collection (if enabled)
	.gc.run[];
	};
	
savealltablesoverperiod:{[dir;nextp]
	t:nextp;
	savetablesoverperiod[dir;;t]each .wdb.tablelist[];
	};


.timer.repeat[00:00+.z.d;0W;0D00:10:00;(`.ds.savealltablesoverperiod;.ds.td;.z.p);"Saving tables"]


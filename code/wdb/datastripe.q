\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values

td:hsym `$getenv`KDBTAIL

\d .

.wdb.datastripeendofperiod:{[currp;nextp;data]
    .lg.o[`reload;"reload command has been called remotely"];    
    // remove periods of data from tables
    t:tables[`.] except .wdb.ignorelist;
    lasttime:currp-.ds.periodstokeep*(nextp-currp);
    tabs:.ds.deletetablebefore'[t;`time;lasttime];
    / tabs:{![x;enlist (<;y;z);0b;0#`]}'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];
    };


initdatastripe:{
	// update endofday and endofperiod functions
    endofperiod::.wdb.datastripeendofperiod;
    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

\d .ds

// function to get handle for rdb and send access table
pubaccess:{[accesstab]
	/- get rdb handle
	w: .sub.getsubscriptionhandles[`rdb;();()!()]`w;
	/- send command down handle to remove specified period
	(neg w)@\:(`.rdb.datastripeendofperiod;accesstab[`end];accesstab[`end];accesstab[`tablename]);
	/- update the wdb access table
	.wdb.access,:accesstab;
	};

upserttopartition:{[dir;tablename;keycol;enumdata;nextp]
	/- function takes a (dir)ectory handle, tablename as a symbol
	/- column to key table on, an enumerated table and a timestamp.
	/- partitions the data on the keycol and upserts it to the given dir
	/- get unique sym from table
	s:first raze value'[?[enumdata;();1b;enlist[keycol]!enlist keycol]];
	/- get process specific taildir location
	dir:` sv dir,.proc.procname,`;
	/- get symbol enumeration
	partitionint:`$string (where s=value [`.]`sym)0;
	/- create directory location for selected partition
	directory:` sv .Q.par[dir;partitionint;tablename],`;
	.lg.o[`save;"Saving ",string[s]," data from ",string[tablename]," table to partition ",string[partitionint],". Table contains ",string[count enumdata]," rows."];
	.lg.o[`save;"Saving data down to ",string[directory]];
	/- upsert select data matched on partition to specific directory
	.[upsert;
	  (directory;enumdata);
	  {[e] .lg.e[`upserttopartition;"Failed to save table to disk : ",e];'e}
	];
	};	

savetablesoverperiod:{[dir;tablename;nextp]
	/- function to get keycol for table from access table
	keycol:$[.wdb.tablekeycols[tablename]=`;`sym;.wdb.tablekeycols[tablename]];
	/- get distint values to partition table on
	partitionlist:raze value each ?[[`.]tablename;();1b;enlist[keycol]!enlist keycol];
	/- enumerate table to be upserted and get each table by sym
	enumdata:{[dir;tablename;keycol;nextp;s] .Q.en[dir;0!?[[`.]tablename;((<;`time;nextp);(=;keycol;enlist s));0b;()]]}[dir;tablename;keycol;nextp]'[partitionlist];
	/-upsert table to partition
	upserttopartition[dir;tablename;keycol;;nextp] each enumdata;
	/- delete data from last period
	.[.ds.deletetablebefore;(tablename;`time;nextp)];
	.[{![x;enlist(<;`time;y);0b;0#`]};(tablename;nextp)];
	/- create an access dict with trapping for case where previous end time value is null
	access:`start`end`tablename`keycol!(.z.d^last .wdb.access[`end] where .wdb.access[`tablename]=tablename;nextp;tablename;keycol);
	/- publish access table to rdb and clear tables in rdb
	pubaccess[access];
	/- save access table
	(` sv(dir;`access.csv)) set .wdb.access;
	/- run a garbage collection (if enabled)
	.gc.run[];
	};
	
savealltablesoverperiod:{[dir;nextp]
	/- function takes the tailer hdb directory handle and a timestamp
	/- saves each table up to given period to their respective partitions
	savetablesoverperiod[dir;;nextp]each .wdb.tablelist[];
	};


.timer.repeat[00:00+.z.d;0W;0D00:10:00;(`.ds.savealltablesoverperiod;.ds.td;.z.p);"Saving tables"]


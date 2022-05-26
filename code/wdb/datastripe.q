\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values

td:hsym `$"/"sv (getenv`KDBTAIL;string .z.d)

\d .

// user definable functions to modify the access table or change how the access table is updated
// leave blank by default
modaccess:{[accesstab]

    .wdb.access:select table,start,end,keycol from accesstab;
    .wdb.access:update localstart:start+01:00,localend:end+01:00,segID:first .ds.segmentid from accesstab;

    };

modupdate:{[accesstab]

    .wdb.access:update localstart:start+01:00,localend:end+01:00 from accesstab;

    };

.wdb.datastripeendofperiod:{[currp;nextp;data]
    .lg.o[`reload;"reload command has been called remotely"];

    // remove periods of data from tables
    t:tables[`.] except .wdb.ignorelist;
    lasttime:nextp-.ds.periodstokeep*(nextp-currp);

    // update the access table in the wdb
    // on first save down we need to replace the null valued start time in the access table
    // using the first value in the saved data
    .wdb.access:update end:nextp,start:(.ds.getstarttime each key .wdb.tablekeycols)^start from .wdb.access;
    modupdate[.wdb.access];

    // call the savedown function
    .ds.savealltablesoverperiod[.ds.td;nextp];

    tabs:.ds.deletetablebefore'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];
    
    // update the access table on disk
    atab:get ` sv(.ds.td;.proc.procname;`access);
    atab,:() xkey .wdb.access;
    (` sv(.ds.td;.proc.procname;`access)) set atab;

    };

initdatastripe:{
    // update endofperiod function
    endofperiod::.wdb.datastripeendofperiod;
    
    .wdb.tablekeycols:.ds.loadtablekeycols[];
    .wdb.access: @[get;(` sv(.ds.td;.proc.procname;`access));([] table:key .wdb.tablekeycols ; start:0Np ; end:0Np ; keycol:value .wdb.tablekeycols)];
    modaccess[.wdb.access];
    (` sv(.ds.td;.proc.procname;`access)) set .wdb.access;
    .wdb.access:{[x] last .wdb.access where .wdb.access[`table]=x} each (key .wdb.tablekeycols);
    .wdb.access:`table xkey .wdb.access;
    };


if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

\d .ds

upserttopartition:{[dir;tablename;keycol;enumdata;nextp;part]
    /- function takes a (dir)ectory handle, tablename as a symbol
    /- column to key table on, an enumerated table and a timestamp.
    /- partitions the data on the keycol and upserts it to the given dir
    
    /- get process specific taildir location
    dir:` sv dir,.proc.procname,`;
    /- get symbol enumeration
    partitionint:`$string (where part=value [`.]`sym)0;
    /- create directory location for selected partition
    directory:` sv .Q.par[dir;partitionint;tablename],`;
    .lg.o[`save;"Saving ",string[part]," data from ",string[tablename]," table to partition ",string[partitionint],". Table contains ",string[count enumdata]," rows."];
    .lg.o[`save;"Saving data down to ",string[directory]];
    /- upsert select data matched on partition to specific directory
    .[upsert;
        (directory;enumdata);
        {[e] .lg.e[`upserttopartition;"Failed to save table to disk : ",e];'e}
    ];
    };

savetablesoverperiod:{[dir;tablename;nextp]
    /- function to get keycol for table from access table
    keycol:`sym^.wdb.tablekeycols tablename;
    /- get distinct values to partition table on
    partitionlist: ?[tablename;();();(distinct;keycol)];
    /- enumerate and then split by keycol
    enumkeycol: .Q.en[dir;?[tablename;enlist (<;`time;nextp);0b;()]];
    splitkeycol: {[s;enumkeycol] ?[enumkeycol;enlist (=;`sym;s);0b;()]}[;enumkeycol]'[enlist partitionlist];
    /-upsert table to partition
    @[upserttopartition[dir;tablename;keycol;;nextp;partitionlist] ; splitkeycol ; ];
    /- delete data from last period
    .[.ds.deletetablebefore;(tablename;`time;nextp)];
    
    /- run a garbage collection (if enabled)
    .gc.run[];
    };

savealltablesoverperiod:{[dir;nextp]
	/- function takes the tailer hdb directory handle and a timestamp
	/- saves each table up to given period to their respective partitions
	savetablesoverperiod[dir;;nextp]each .wdb.tablelist[];
	};

.timer.repeat[00:00+.z.d;0W;0D00:10:00;(`.ds.savealltablesoverperiod;.ds.td;.z.p);"Saving tables"]

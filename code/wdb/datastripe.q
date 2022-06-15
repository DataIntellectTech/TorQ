\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values

td:hsym `$"/"sv (getenv`KDBTAIL;string .z.d)

\d .

// user definable functions to modify the access table or change how the access table is updated
// leave blank by default
modaccess:{[accesstab]};

.wdb.datastripeendofperiod:{[currp;nextp;data]

    .lg.o[`reload;"reload command has been called remotely"];

    // remove periods of data from tables
    t:tables[`.] except .wdb.ignorelist;
    lasttime:nextp-.ds.periodstokeep*(nextp-currp);

    // update the access table in the wdb
    // on first save down we need to replace the null valued start time in the access table
    // using the first value in the saved data
    starttimes:.ds.getstarttime each t;
    .wdb.access:update start:starttimes^start, end:?[(nextp>starttimes)&(starttimes<>0Np);nextp;0Np], stptime:data[][`time] from .wdb.access;
    modaccess[.wdb.access];

    // call the savedown function
    .ds.savealltablesoverperiod[.ds.td;nextp;lasttime];

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
    
    .wdb.tablekeycols:.ds.loadtablekeycols[];  // replace with dictionaries from json file
    t:tables[`.] except .wdb.ignorelist;
    .wdb.access: @[get;(` sv(.ds.td;.proc.procname;`access));([] table:t ; start:0Np ; end:0Np ; stptime:0Np ; keycol:`sym^.wdb.tablekeycols[t])];
    modaccess[.wdb.access];
    (` sv(.ds.td;.proc.procname;`access)) set .wdb.access;
    .wdb.access:{[x] last .wdb.access where .wdb.access[`table]=x} each (key .wdb.tablekeycols);
    .wdb.access:`table xkey .wdb.access;
    };


if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

\d .ds

upserttopartition:{[dir;tablename;keycol;enumdata;nextp]
        /- function takes a (dir)ectory handle, tablename as a symbol
        /- column to key table on, an enumerated table and a timestamp.
        /- partitions the data on the keycol and upserts it to the given dir
        /- get unique sym from table
        s:first raze value'[?[enumdata;();1b;enlist[keycol]!enlist keycol]];
        /- get process specific taildir location
        dir:` sv dir,.proc.procname,`$ string .wdb.currentpartition;
        /- get symbol enumeration
        partitionint:`$string (where s=value [`.]keycol)0;
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

savetablesoverperiod:{[dir;tablename;nextp;lasttime]
    /- function to get keycol for table from access table
    keycol:`sym^.wdb.tablekeycols tablename;

    /- get distinct values to partition table on
    partitionlist: ?[tablename;();();(distinct;keycol)];

    /- enumerate and then split by keycol
    enumkeycol: .Q.en[dir;?[tablename;enlist (<;`time;nextp);0b;()]];
    splitkeycol: {[enumkeycol;keycol;s] ?[enumkeycol;enlist (=;keycol;enlist s);0b;()]}[enumkeycol;keycol;] each partitionlist;

    /-upsert table to partition
    @[upserttopartition[dir;tablename;keycol;;nextp;partitionlist] ; splitkeycol ; ];

    /- delete data from last period
    .[.ds.deletetablebefore;(tablename;`time;lasttime)];
    
    /- run a garbage collection (if enabled)
    .gc.run[];
    };

savealltablesoverperiod:{[dir;nextp;lasttime]
    /- function takes the tailer hdb directory handle and a timestamp
    /- saves each table up to given period to their respective partitions
    savetablesoverperiod[dir;;nextp;lasttime]each .wdb.tablelist[];
    /- trigger reload of access tables and intradayDBs in all tail reader processes
    .wdb.dotailreload[`]};

.timer.repeat[00:00+.z.d;0W;0D00:10:00;(`.ds.savealltablesoverperiod;.ds.td;.z.p);"Saving tables"]
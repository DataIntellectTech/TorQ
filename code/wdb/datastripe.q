\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values

td:hsym `$getenv`KDBTAIL

\d .

// user definable functions to modify the access table or change how the access table is updated
// leave blank by default
modaccess:{[accesstab]};

.wdb.datastripeendofday:{[pt;processdata]
    //- WORK-IN-PROGRESS
    "If you can see this, please ask Conor Gallagher to finish his ticket!"

    .lg.o[`eod;"end of day message received - ",spt:string pt];
    /- create a dictionary of tables and merge limits
    mergelimits:(tablelist[],())!({[x] mergenumrows^mergemaxrows[x]}tablelist[]),();
    tablist:tablelist[]!{0#value x} each tablelist[];
    / - if save mode is enabled then flush all data to disk
    if[saveenabled;
        endofdaysave[savedir;pt];



        //- Create Access table query; use response for if-else statement - sorting must wait until after *all* savedowns are finished!

        if[(enlist 23:59:59.000) ~ distinct exec time from select end.time from .wdb.access where end <> 0N;
        / - if sort mode enable call endofdaysort within the process,else inform the sort and reload process to do it
        $[sortenabled;endofdaysort;informsortandreload] . (savedir;pt;tablist;writedownmode;mergelimits;hdbsettings)]];
        



    .lg.o[`eod;"deleting data from tabsizes"];
    @[`.wdb;`tabsizes;0#];
    .lg.o[`eod;"end of day is now complete"];
    .wdb.currentpartition:pt+1;
    };

.wdb.datastripeendofperiod:{[currp;nextp;data]

    .lg.o[`reload;"reload command has been called remotely"];

    .lg.o[`debugperiod1;"Filtering data from tables..."];
    // remove periods of data from tables
    t:tables[`.] except .wdb.ignorelist;
    lasttime:nextp-.ds.periodstokeep*(nextp-currp);

    .lg.o[`debugperiod2;"Updating access table. Current stptime type is: ",exec t from (meta .wdb.access)`stptime];
    .lg.o[`debugperiod2a;"stptime value is: ",.Q.s1 data[][`p]];
    // update the access table in the wdb
    // on first save down we need to replace the null valued start time in the access table
    // using the first value in the saved data
    starttimes:.ds.getstarttime each t;
    .lg.o[`debugperiod2b;"starttimes variable defined. Incoming stptime type is: ",.Q.s1[type data[][`p]]];
    .wdb.access:update start:starttimes^start, end:?[(nextp>starttimes)&(starttimes<>0Np);nextp;0Np], stptime:data[][`p] from .wdb.access;
    .lg.o[`debugperiod2c;".wdb.access updated. stptime type is: ",exec t from (meta .wdb.access)`stptime];
    modaccess[.wdb.access];

    // call the savedown function
    .lg.o[`debugperiod3;"Calling endofperiod savedown function..."];
    .ds.savealltablesoverperiod[.ds.td;nextp;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[t]];
    
    .lg.o[`debugperiod4;"Updating on-disk access table. stptime type is: ",exec t from (meta .wdb.access)`stptime];
    // update the access table on disk
    atab:get ` sv(.ds.td;.proc.procname;`access);
    .lg.o[`debugperiod4a;"On-disk access table loaded into memory. stptime type is: ",exec t from (meta .wdb.access)`stptime];
    atab,:() xkey .wdb.access;
    .lg.o[`debugperiod4b;"Access table appended to. stptime type is: ",exec t from (meta .wdb.access)`stptime];
    (` sv(.ds.td;.proc.procname;`access)) set atab;

    .lg.o[`debugperiod5;"endofperiod function complete."];

    };

initdatastripe:{
    // update endofday & endofperiod functions
    /- datastripeendofday[] propagation on stand-by; awaiting confirmation of requirement.
    /- endofday::.wdb.datastripeendofday;
    endofperiod::.wdb.datastripeendofperiod;
    
    // load in variables
    .wdb.tablekeycols:.ds.loadtablekeycols[];
    t:tables[`.] except .wdb.ignorelist;

    // create or load the access table
    .wdb.access: @[get;(` sv(.ds.td;.proc.procname;`access));([] table:t ; start:0Np ; end:0Np ; stptime:0Np ; keycol:`sym^.wdb.tablekeycols[t])];
    modaccess[.wdb.access];
    (` sv(.ds.td;.proc.procname;`access)) set .wdb.access;
    .wdb.access:{[x] last .wdb.access where .wdb.access[`table]=x} each t;
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
    symdir:` sv dir,.proc.procname;
    enumkeycol: .Q.en[symdir;?[tablename;enlist (<;`time;nextp);0b;()]];
    splitkeycol: {[enumkeycol;keycol;s] ?[enumkeycol;enlist (=;keycol;enlist s);0b;()]}[enumkeycol;keycol;] each partitionlist;

    /-upsert table to partition
    upserttopartition[dir;tablename;keycol;;nextp] each splitkeycol where 0<count each splitkeycol; 

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
    .lg.o[`debugsave;"Calling dotailreload function..."];
    .wdb.dotailreload[`]};

.timer.repeat[00:00+.z.d;0W;0D00:10:00;(`.ds.savealltablesoverperiod;.ds.td;.z.p);"Saving tables"]

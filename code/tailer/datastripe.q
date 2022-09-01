\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values

td:hsym `$getenv`KDBTAIL

\d .

// user definable functions to modify the access table or change how the access table is updated
// leave blank by default
modaccess:{[accesstab]};

.wdb.datastripeendofperiod:{[currp;nextp;data]
    // 'data' argument constructed in 'segmentedtickerplant/stplog.q' using .stplg.endofperioddata[], and (enlist `p)!enlist .z.p+.eodtime.dailyadj

    .lg.o[`reload;"reload command has been called remotely"];

    // remove periods of data from tables
    lasttime:nextp-.ds.periodstokeep*(nextp-currp);

    // update the access table in the wdb
    // on first save down we need to replace the null valued start time in the access table
    // using the first value in the saved data
    starttimes:.ds.getstarttime each .wdb.tablelist[];
    .ds.access:update start:starttimes^start, end:?[(nextp>starttimes)&(starttimes<>0Np);nextp;0Np], stptime:data[][`p] from .ds.access;
    modaccess[.ds.access];

    // call the savedown function
    .ds.savealltables[.ds.td];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[.wdb.tablelist[]]];
    
    // update the access table on disk
    accesspath: ` sv(.ds.td;.proc.procname;`$ string .wdb.currentpartition;`access);
    atab:get accesspath;
    atab,:() xkey .ds.access;
    accesspath set atab;

    // update the access table in the gateway
    handles:(.servers.getservers[`proctype;`gateway;()!();1b;1b])[`w];
    .ds.updategw each handles;

    };

.wdb.datastripeendofday:{[pt;processdata]
    //save all tables
    .ds.savealltables[.ds.td];
    //move to next partition
    .wdb.currentpartition:pt+1;
    //create accesspath
    accesspath: ` sv(.ds.td;.proc.procname;`$ string .wdb.currentpartition;`access);
    //define access for next partition
    .ds.access:([]table:.wdb.tablelist[]; start:0Np; end:0Np; stptime:0Np; keycol:`sym^.wdb.tablekeycols .wdb.tablelist[]);
    modaccess[.ds.access];
    accesspath set .ds.access;
    };

initdatastripe:{
    // update endofperiod function
    endofperiod::.wdb.datastripeendofperiod;
    
    //update endofday function
    endofday::.wdb.datastripeendofday;
	
    // load in variables
    .wdb.tablekeycols:.ds.loadtablekeycols[];
    accesspath: ` sv(.ds.td;.proc.procname;`$ string .wdb.currentpartition;`access);

    // load the access table; fall back to generating table if load fails
    default:([]table:.wdb.tablelist[]; start:0Np; end:0Np; stptime:0Np; keycol:`sym^.wdb.tablekeycols .wdb.tablelist[]);
    .ds.access: @[get;accesspath;default];
    modaccess[.ds.access];
    .ds.checksegid[];
    accesspath set .ds.access;      
    .ds.access:select by table from .ds.access where table in .wdb.tablelist[];
    };

\d .ds

symlink:{
    /- function to create HDB sym file and symlink to this sym file at start up
    /- create HDB sym file
    sympath:` sv (.wdb.hdbdir;`sym);
    .lg.o[`hdbsym;"creating HDB sym file"];
    if[not `sym in key .wdb.hdbdir;sympath set `symbol$()];

    /- create symlink
    basedir:` sv .ds.td,.proc.procname;
    .lg.o[`symlink;"creating symlink"];
    if[not `sym in key basedir;createsymlink[basedir;.wdb.hdbdir;`sym]];
    };

createsymlink:{[tdpath;hdbpath;symfile]
    /- function to create symlink to HDB sym file in taildir
    tdsympath:1_string ` sv (tdpath;symfile);
    hdbsympath:1_string ` sv (hdbpath;symfile);

    /- linux command to create symlink in specified dirs
    symlink:{system"ln -s ",x," ",y};
    .[symlink;
        (hdbsympath;tdsympath);
        {[e] .lg.e[`createsymlink;"Failed to create symlink : ",e];e}
    ];
    };

upserttopartition:{[dir;tablename;keycol;enumdata]
    /- function takes a (dir)ectory handle, tablename as a symbol
    /- column to key table on, an enumerated table and a timestamp.
    /- partitions the data on the keycol and upserts it to the given dir
    
    /- get unique sym from table
    s:first raze value'[?[enumdata;();1b;enlist[keycol]!enlist keycol]];

    /- get process specific taildir location
    basedir:` sv dir,.proc.procname;
    dir:` sv basedir,`$ string .wdb.currentpartition;

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

    /- check if sym file exists in taildir, create symlink to HDB sym file if not
    if[not `sym in key hsym basedir;createsymlink[basedir;.wdb.hdbdir;`sym]];
    };

savetables:{[dir;tablename]
    /- function to get keycol for table from access table
    keycol:`sym^.wdb.tablekeycols tablename;

    /- get distinct values to partition table on
    partitionlist: ?[tablename;();();(distinct;keycol)];

    /- enumerate and then split by keycol
    symdir:` sv dir,.proc.procname;
    enumkeycol: .Q.en[symdir;value tablename];
    splitkeycol: {[enumkeycol;keycol;s] ?[enumkeycol;enlist (=;keycol;enlist s);0b;()]}[enumkeycol;keycol;] each partitionlist;

    /-upsert table to partition
    upserttopartition[dir;tablename;keycol;] each splitkeycol where 0<count each splitkeycol; 
    
    /- run a garbage collection (if enabled)
    .gc.run[];
    };

savealltables:{[dir]
    /- function takes the tailer hdb directory handle and a timestamp
    /- saves each table up to given period to their respective partitions
    savetables[dir;]each .wdb.tablelist[];

    /- delete data that has been saved
    @[`.;;0#] each .wdb.tablelist[];

    /- trigger reload of access tables and intradayDBs in all tail reader processes
    .tailer.dotailreload[`]};

savedownfilter:{[]
    /- checks each table in memory against a size threshold
    /- saves any tables above that threshold
    totals:{count value x}each .wdb.tablelist[];
    /- log and return from function early if no table has crossed threshold
    if[all totals<.wdb.numrows;
        .lg.o[`save;"No tables above threshold, no tables saved"];
        :();
    ];

    /- log and savedown any tables above threshold
    .lg.o[`save;"Saving ",(", " sv string tabstosave:.wdb.tablelist[] where totals>.wdb.numrows)," table(s)"];
    savetables[dir;]each tabstosave;

    /- delete data that has been saved
    @[`.;;0#] each tabstosave;

    /- trigger reload of access tables and intradayDBs in all tail reader processes
    .tailer.dotailreload[`]
    };

/- Timer to repeat savealltables with period defined in tailer.q settings
.timer.repeat[00:00+.z.d;0W;.wdb.settimer;(`.ds.savedownfilter;.ds.td);"Saving tables"];
getaccess:{[] `location`table xkey update location:.proc.procname,proctype:.proc.proctype from .ds.access};

// function to update the access table in the gateway. Takes the gateway handle as argument
updategw:{[h]

    newtab:getaccess[];
    neg[h](`.ds.updateaccess;newtab);

    };

\d .ds

td:hsym `$getenv`KDBTAIL

\d .

// user definable functions to modify the access table or change how the access table is updated
// leave blank by default
modaccess:{[accesstab]};

.wdb.tablekeycols:.ds.loadtablekeycols[];

.wdb.datastripeendofperiod:{[currp;nextp;data]
    // 'data' argument constructed in 'segmentedtickerplant/stplog.q' using .stplg.endofperioddata[], and (enlist `p)!enlist .z.p+.eodtime.dailyadj

    .lg.o[`reload;"reload command has been called remotely"];

    // update the access table in the wdb
    // on first save down we need to replace the null valued start time in the access table
    // using the first value in the saved data
    starttimes:.ds.getstarttime each .wdb.tablelist[];
    .ds.access:update start:starttimes^start, end:?[(nextp>starttimes)&(starttimes<>0Np);nextp;0Np], stptime:data[][`p] from .ds.access;
    modaccess[.ds.access];

    // call the savedown function
    .ds.savealltables[.ds.td];
    
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
    .ds.access:([]table:.wdb.tablelist[]; start:0Np; end:0Np; stptime:0Np; keycol:`sym^.wdb.tablekeycols .wdb.tablelist[]; segment:first .ds.segmentid);
    modaccess[.ds.access];
    accesspath set .ds.access;
    };

//Function to be called on startup if access table isn't up to date (i.e tailer down during normal EOP)
accessreplay:{[currpd;lastaccess]
    // defines data to be used for manual EOP call
    replaydata:`proctype`procname`tables`time`p!(.proc.proctype;.proc.procname;.stpps.t;.z.P;.z.p+.eodtime.dailyadj);
    .lg.o[`accessreplay;"doing manual endofperiod replay..."];
    endofperiod[(first(exec x from lastaccess));.z.p;replaydata];
    .lg.o[`accessreplay;"replay was a success"];
    };

initdatastripe:{
    // update endofperiod function
    endofperiod::.wdb.datastripeendofperiod;

    // load in variables
    .wdb.tablekeycols:.ds.loadtablekeycols[];
    accesspath: ` sv(.ds.td;.proc.procname;`$ string .wdb.currentpartition;`access);

    // load the access table; fall back to generating table if load fails
    default:([]table:.wdb.tablelist[]; start:0Np; end:0Np; stptime:0Np; keycol:`sym^.wdb.tablekeycols .wdb.tablelist[]; segment:first .ds.segmentid);
    .ds.access: @[get;accesspath;default];
    modaccess[.ds.access];
    .ds.checksegid[];
    accesspath set .ds.access;      
    .ds.access:select by table from .ds.access where table in .wdb.tablelist[];

    // Variables set up for lastcall check
    stphandle:$[count u:(.servers.getservers[`proctype;`segmentedtickerplant;()!();1b;1b])[`w];u;.lg.e[`stphandle;"Failed to retrieve handle of stp"]];
    currentperiod:@[(first stphandle);".stplg.currperiod";{.lg.e[`currentP;"Couldn't retrieve current period from stp with error:",x]}];
    nextperiod:@[(first stphandle);".stplg.nextperiod";{.lg.e[`nextP;"Couldn't retrieve next period from stp with error:",x]}];

    // Check carried out to see if access table is up to date relative to most recent EOP, if not then EOP is called manually to get the access table data up to date
    lastcall:select last end where end<>0N from .ds.access;
    $[first(((enlist nextperiod)>=(exec x from lastcall))&((exec x from lastcall)>=(enlist currentperiod)));.lg.o[`accessreplay;"Most recent time on access table is up to date"];accessreplay[currentperiod;lastcall]];

    // Fills tailDB if any tables are missing as a result of tables containing different keycol filters and therefore saving down to only some keycol partitions
    .Q.chk[` sv .ds.td,.proc.procname,`$ string .wdb.currentpartition];
    .tailer.dotailreload[`];
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

savedownfilter:{[dir]
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

/- Timer to call savedownfilter with period defined in tailer.q settings
.timer.repeat[00:00+.z.d;0W;.wdb.settimer;(`.ds.savedownfilter;.ds.td);"Saving tables"];
getaccess:{[] `location`table xkey update location:.proc.procname,proctype:.proc.proctype from .ds.access};

// function to update the access table in the gateway. Takes the gateway handle as argument
updategw:{[h]

    newtab:getaccess[];
    neg[h](`.ds.updateaccess;newtab);

    };

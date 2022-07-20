.rdb.extendperiods:.ds.periodstokeep
.rdb.datastripeendofperiod:{[currp;nextp;data]

    .lg.o[`reload;"reload command has been called remotely"];

    t:tables[`.] except .rdb.ignorelist;

    // check if tail sort process is complete
    if[.rdb.tailsortcomplete;.rdb.extendperiods:.ds.periodstokeep];

    // clear data from tables
    lasttime:nextp-.rdb.extendperiods*(nextp-currp);
    // if eop occurs while tail sort in progress, extend number of periods kept in memory until tailsort complete
    tabs:$[.rdb.tailsortcomplete;.ds.deletetablebefore'[t;`time;lasttime];.rdb.extendperiods+:1];
    .lg.o[`reload;"Kept ",string[.rdb.extendperiods]," period",$[.rdb.extendperiods>1;"s";""]," of data from : ",", " sv string[t]];

    // update the access table in the rdb
    .rdb.access:update start:lasttime^(.ds.getstarttime each key .rdb.tablekeycols), stptime:data[][`time] from .rdb.access;
    modaccess[.rdb.access];

    };

// end of day function - no savedown functionality, just wipes tables and updates date partition
.rdb.datastripeendofday:{[date;processdata]
    .rdb.tailsortcomplete:0b;
    // add date+1 to rdbpartition global
    .rdb.rdbpartition,:: date+1;
    .lg.o[`rdbpartition;"rdbpartition contains - ","," sv string .rdb.rdbpartition];
    t:tables[`.] except .rdb.ignorelist;
    .lg.o[`clear;"Wiping following tables - ","," sv string t];
    @[`.;t;0#];
    .rdb.rmdtfromgetpar[date];
    };

// user definable function to modify the access table
modaccess:{[accesstab]};

initdatastripe:{
    // update endofperiod function
    endofperiod::.rdb.datastripeendofperiod;
    endofday::.rdb.datastripeendofday;
    .rdb.tailsortcomplete:1b;
    .rdb.tablekeycols:.ds.loadtablekeycols[];
    t:tables[`.] except .rdb.ignorelist;
    .rdb.access:([table:t] start:.ds.getstarttime each t; end:0Np ; stptime:0Np ; keycol:`sym^.rdb.tablekeycols[t]);
    modaccess[.rdb.access];

    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];


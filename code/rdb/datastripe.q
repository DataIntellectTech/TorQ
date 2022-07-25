.rdb.datastripeendofperiod:{[currp;nextp;data]

    .lg.o[`reload;"reload command has been called remotely"];

    t:tables[`.] except .rdb.ignorelist;

    // clear data from tables
    lasttime:nextp-.ds.periodstokeep*(nextp-currp);
    tabs:.ds.deletetablebefore'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];

    // update the access table in the rdb
    t:tables[`.] except .rdb.ignorelist;
    starttimes:.ds.getstarttime each t;
    .rdb.access:update start:starttimes, stptime:data[][`time] from .rdb.access;
    /.rdb.access:update start:lasttime^(.ds.getstarttime each key .rdb.tablekeycols), stptime:data[][`time] from .rdb.access;
    modaccess[.rdb.access];

    };

// user definable function to modify the access table
modaccess:{[accesstab]};

initdatastripe:{
    // update endofperiod function
    endofperiod::.rdb.datastripeendofperiod;
    .rdb.tablekeycols:.ds.loadtablekeycols[];
    t:tables[`.] except .rdb.ignorelist;
    .rdb.access:([table:t] start:.ds.getstarttime each t; end:0Np ; stptime:0Np ; keycol:`sym^.rdb.tablekeycols[t]);
    modaccess[.rdb.access];
    .ds.checksegid[];    
    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];


\d .rdb

datastripeendofperiod:{[currp;nextp;data]

    if[.proc.localtime~1b;currp:currp-.ds.timediff;nextp:nextp-.ds.timediff];

    .lg.o[`reload;"reload command has been called remotely"];

    // get list of tables except ignored tables
    t:tables[`.] except ignorelist;

    // clear data from tables
    lasttime:nextp-.ds.periodstokeep*(nextp-currp);
    tabs:.ds.deletetablebefore'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];

    // update the access table in the rdb
    .rdb.access:update exchangestart:lasttime^(.ds.getstarttime each key .rdb.tablekeycols), localstart:exchangestart+.ds.timediff from .rdb.access;
    modaccess[.rdb.access];

    };

\d .

// user definable function to modify the access table
modaccess:{[accesstab]};

initdatastripe:{
    // update endofperiod function
    endofperiod::.rdb.datastripeendofperiod;
    .rdb.tablekeycols:.ds.loadtablekeycols[];
    .rdb.access:([table:key .rdb.tablekeycols] exchangestart:.ds.getstarttime each (key .rdb.tablekeycols) ; exchangeend:0Np ; localstart:exchangestart + .ds.timediff ; localend:0Np ; keycol:value .rdb.tablekeycols);
    modaccess[.rdb.access];

    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];


.rdb.datastripeendofperiod:{[currp;nextp;data]

    .lg.o[`reload;"reload command has been called remotely"];

    t:tables[`.] except .rdb.ignorelist;

    // clear data from tables
    lasttime:nextp-.ds.periodstokeep*(nextp-currp);
    tabs:.ds.deletetablebefore'[t;`time;lasttime];
    .lg.o[`reload;"Kept ",string[.ds.periodstokeep]," period",$[.ds.periodstokeep>1;"s";""]," of data from : ",", " sv string[tabs]];

    // update the access table in the rdb
    .ds.access:update start:.ds.getstarttime each table, stptime:data[][`time] from .ds.access;
    modaccess[.ds.access];

    // update the access table in the gateway
    handles:(.servers.getservers[`proctype;`gateway;()!();1b;1b])[`w];
    .ds.updategw each handles;

    };

// user definable function to modify the access table
modaccess:{[accesstab]};

initdatastripe:{
    // update endofperiod function
    endofperiod::.rdb.datastripeendofperiod;
    .rdb.tablekeycols:.ds.loadtablekeycols[];
    t:tables[`.] except .rdb.ignorelist;
    .ds.access:([table:t] start:.ds.getstarttime each t; end:0Np ; stptime:0Np ; keycol:`sym^.rdb.tablekeycols[t]);
    modaccess[.ds.access];
    .ds.checksegid[];    
    };


\d .ds

getaccess:{[] `location`table xkey update location:.proc.procname,proctype:.proc.proctype from .ds.access};

// function to update the access table in the gateway. Takes the gateway handle as argument
updategw:{[h]

    newtab:getaccess[];
    neg[h](`.ds.updateaccess;newtab);

    };
    

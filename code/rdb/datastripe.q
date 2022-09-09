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
    .ds.access:update start:.ds.getstarttime each t,stptime:data[][`time] from .ds.access;
    modaccess[.ds.access];

    // update the access table in the gateway
    handles:(.servers.getservers[`proctype;`gateway;()!();1b;1b])[`w];
    .ds.updategw each handles;

    };

// end of day function - no savedown functionality, just wipes tables and updates date partition
.rdb.datastripeendofday:{[date;processdata]
    .rdb.tailsortcomplete:0b;
    // add date+1 to rdbpartition global
    .rdb.rdbpartition,:: date+1;
    .lg.o[`rdbpartition;"rdbpartition contains - ", "," sv string .rdb.rdbpartition];
    t:tables[`.] except .rdb.ignorelist;
    .lg.o[`clear;"Wiping following tables - ", "," sv string t];
    @[`.;t;0#];
    .rdb.rmdtfromgetpar[date];
    };

.rdb.getaccessdata:{[dir]
    t:tables[`.] except .rdb.ignorelist;
    .ds.access:update start:.ds.getstarttime each t from .ds.access;
    .ds.checksegid[];
    handles:(.servers.getservers[`proctype;`gateway;()!();1b;1b])[`w];
    .ds.updategw each handles;
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
    .ds.access:([table:t] start:.ds.getstarttime each t; end:0Np ; stptime:0Np ; keycol:`sym^.rdb.tablekeycols[t]; segment:first .ds.segmentid);
    modaccess[.ds.access];
    .ds.checksegid[];   
    handles:(.servers.getservers[`proctype;`gateway;()!();1b;1b])[`w];
    .ds.updategw each handles;
    //If rdb1 is started it has no data as the feed is started after the rdb1 resulting in no access data
    //Use a timer and wait for ten seconds for feed/gateway to start to allow rdb1 to save access tables 
    if[.proc.procname~`rdb1;.timer.one[(.proc.cp[]+0D00:00:10);(`.rdb.getaccessdata;`);"Update rdb access table";0b]]; 
    };


\d .ds

getaccess:{[] `location`table xkey update location:.proc.procname,proctype:.proc.proctype from .ds.access};

// function to update the access table in the gateway. Takes the gateway handle as argument
updategw:{[h]

    newtab:getaccess[];
    neg[h](`.ds.updateaccess;newtab);

    };
    

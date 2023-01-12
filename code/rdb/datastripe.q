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
    .ds.access:update start:.ds.getstarttime each table, stptime:data[][`time] from .ds.access;
    modaccess[.ds.access];

    // update the access table in the gateway
    handles:(.servers.getservers[`proctype;`gateway;()!();1b;1b])[`w];
    .ds.updategw each handles;

    };

.rdb.datastripeendofday:{[date;processdata]
    .lg.o[`endofday;"end of day message received"];
	/-add date+1 to the rdbpartition global
	.rdb.rdbpartition,:: date +1;
	.lg.o[`rdbpartition;"rdbpartition contains - ","," sv string .rdb.rdbpartition];
	/-if reloadenabled is true, then set a global with the current table counts and then escape
	if[.rdb.reloadenabled;
		.rdb.eodtabcount:: tables[`.] ! count each value each tables[`.];
		.lg.o[`endofday;"reload is enabled - storing counts of tables at EOD : ",.Q.s1 .rdb.eodtabcount];
		/-set eod attributes on gateway for rdb
		gateh:exec w from .servers.getservers[`proctype;.rdb.gatewaytypes;()!();1b;0b];
		.async.send[0b;;(`setattributes;.proc.procname;.proc.proctype;.proc.getattributes[])] each neg[gateh];
		.lg.o[`endofday;"Escaping end of day function"];:()
    ];
	t:tables[`.] except .rdb.ignorelist;
	/-get a list of pairs (tablename;columnname!attributes)
	a:{(x;raze exec {(enlist x)!enlist((#);enlist y;x)}'[c;a] from meta x where not null a)}each tables`.;
	/-reset timeout to original timeout
	.rdb.restoretimeout[];
	/-reapply the attributes
	/-functional update is equivalent of {update col:`att#col from tab}each tables
	(![;();0b;].)each a where 0<count each a[;1];
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
    

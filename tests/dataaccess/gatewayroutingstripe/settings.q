// IPC connection parameters                                                                                             .servers.CONNECTIONS:`discovery`segmentedtickerplant`rdb`hdb`gateway;
.servers.USERPASS:`admin:admin;

// STP updates
syms:`AMD`AIG`AAPL`DELL`DOW`GOOG`HPQ`INTC`IBM`MSFT
/random syms
rsyms:`$upper distinct raze{x cut (x*50000)?" "}'[3+til 3]
ls:raze(ls2:12+til 73)+/:0.01*til 100
src:`BARX`GETGO`SUN`DB
q:{[syms;len;ls;ls2;src] len?/:(syms;ls;ls;ls2;ls2;" 89ABCEGJKLNOPRTWZ";"NO";src)}[;;ls;ls2;src]
t:{[syms;len;ls;ls2;src] len?/:(syms;ls;`int$ls2;01b;" 89ABCEGJKLNOPRTWZ";"NO";`buy`sell)}[;;ls;ls2;src]

// Checks
quotecols:`time`sym`bid`ask`bsize`asize`mode`ex`src
tradecols:`time`sym`price`size`stop`cond`ex`side

/randomize cols
quotecols:first[1+1?count columns]#0N?columns:quotecols
tradecols:first[1+1?count columns]#0N?columns:tradecols

today:.z.d
now:.z.p
hdbdate:2022.01.03
syms1:(1?syms)0
syms2:(10?rsyms),2?syms
syms3:(100?rsyms),4?syms

/ 1 - check rdb only
/ time type
query1:`tablename`starttime`endtime`instruments`columns!(`quote;now-01:00;now;syms1;quotecols)
/ date type
query2:`tablename`starttime`endtime`instruments`columns!(`trade;today;today;syms2;tradecols)
query3:`tablename`starttime`endtime`instruments`columns!(`quote;today;today;syms3;quotecols)
/ a - check without instruments
query4:`tablename`starttime`endtime`columns!(`trade;today;today;tradecols)
/ b - check without instruments and with aggregations
query5:`tablename`starttime`endtime`aggregations!(`quote;today;today;`max`min!(`ask`bid;`ask`bid))

/ 2 - check hdb only
/ time type
query6:`tablename`starttime`endtime`instruments`columns!(`quote;hdbdate+0D;hdbdate+12:00;syms2;quotecols)
/ date type
/ a - check without instruments
query7:`tablename`starttime`endtime`columns!(`trade;hdbdate;hdbdate;tradecols)
/ b - check without instruments and with aggregations
query8:`tablename`starttime`endtime`aggregations!(`quote;hdbdate;hdbdate;`max`min!(`ask`bid;`ask`bid))

/ 3 - check both rdb and hdb simultaneously
/ date type
query9:`tablename`starttime`endtime`instruments`columns!(`quote;hdbdate;today;syms2;quotecols)
/ time type
query10:`tablename`starttime`endtime`instruments`columns!(`quote;hdbdate+0D;now;syms2;quotecols)
/ a - check without instruments
query11:`tablename`starttime`endtime`columns!(`trade;hdbdate+0D;now;tradecols)
/ b - check without instruments and with aggregations
query12:`tablename`starttime`endtime`aggregations!(`quote;hdbdate+0D;now;`max`min!(`ask`bid;`ask`bid))

// Checker function
checker:{[gwHandle;rdbHandles;hdbHandle;querydict]
    // dataaccess API result                                                                                                 
	daresult:gwHandle(`.dataaccess.getdata;querydict);

    // test result
    /init query
    query:"select ";
    /if columns are given
    if[`columns in k:key querydict;
        query,:","sv string(),querydict`columns];
    /from tablename
    query,:" from ",string querydict`tablename;

    /init results
    rdbresult:hdbresult:();

    // query rdbs
    if[.z.d in dates:`date$times:querydict`starttime`endtime;
		rdbquery:query;
        /not date format
        if[not 14h~type times;
            rdbtimes:`timestamp$0 0;
            /starttime <= endtime
            rdbtimes[0]:$[(t:times 0)<d:.z.d+00:00;d;t];
            rdbtimes[1]:$[(t:times 1)>n:-00:00:00.000000001+.z.d+1;n;t];
            rdbquery,:" where(time within(",(";"sv string rdbtimes),"))";];
        /if instruments are given
        whichrdb:rdbHandles;
        if[i:`instruments in k;
            $[rdbquery like "*where*";
                rdbquery,:"&sym in ",raze"`",/:string instr:(),querydict`instruments;
                rdbquery,:" where sym in ",raze"`",/:string instr:(),querydict`instruments];];
        /check which rdb to query
        /check if all striped
        $[all f:rdbHandles@\:".rdb.subfiltered";
            /and instruments given
            if[i;whichrdb:value[rdbHandles]key gwHandle(`.ds.map;gwHandle".ds.numseg";instr)];
            /get first rdb where not striped
            whichrdb:whichrdb(),first where not f];
        rdbresult:raze whichrdb@\:rdbquery;
        ];
	
	// query hdb (assume unstriped)                                                                                          
	if[any .z.d>dates;
        hdbquery:query;
        /not date format
        if[not 14h~type times;
            hdbtimes:`timestamp$0 0;
            /starttime <= endtime
            hdbtimes[0]:times 0;
            hdbtimes[1]:$[(t:times 1)<n:-00:00:00.000000001+.z.d+1;t;n];
            hdbquery,:" where(time within(",(";"sv string hdbtimes),"))";];
        /if instruments are given
        if[`instruments in k;
            $[hdbquery like "*where*";
                hdbquery,:"&sym in ",raze"`",/:string instr:(),querydict`instruments;
                hdbquery,:" where sym in ",raze"`",/:string instr:(),querydict`instruments];];
        hdbresult:hdbHandle@hdbquery;
        ];

	// Combine rdb and hdb results
    /assumes rdb is queried before hdb (if not requires a sort)
    tresult:rdbresult uj hdbresult;
    /if aggregations are given
    if[`aggregations in key querydict;
        `tresult set tresult;
        dict:querydict`aggregations;
        aggr:","sv raze{a:(f:string x),/:" ",/:c:string y;
            (f,/:@[;0;upper]each c),'":",/:a}'[key dict;value dict];
        tresult:eval parse"select ",aggr," from tresult"];

    // Sort by cols and check all rows match
    {(~) .{cols[x]xasc y}[x]@/:(x;y)}[daresult;tresult]
    }

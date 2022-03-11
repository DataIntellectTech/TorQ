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
/ c - check with procs, additional filter
query13:`tablename`starttime`endtime`instruments`columns`procs!(`quote;hdbdate+0D;now;syms2;quotecols;`rdb)

/set timeout for all querydict
timeout:`timespan$00:00.01
{querydict:get x;querydict[`timeout]:timeout;x set querydict}each k where (k:key`.)like"query[0-9]*"

// Checker function
checker:{[gwHandle;rdbHandles;hdbHandles;querydict;checkavail]
    // check availability for partial and no striped case
    if[checkavail&((not all s)&any s)|all not s:rdbHandles@\:".rdb.subfiltered";
        // simulate server in use
        gwHandle"update inuse:1b from`.gw.servers where serverid in 1 3 5i"];

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

    /procs not given or procs given and matches
    if[(noprocs:not`procs in key querydict)|`rdb in p:querydict`procs;
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
                /get first avail rdb where not striped
                [avail:gwHandle"exec not inuse from .gw.servers where servertype=`rdb";
                whichrdb:whichrdb(),first where avail&not f]];
            rdbresult:raze whichrdb@\:rdbquery;
            ];
        ];

    /procs not given or procs given and matches
    if[noprocs|`hdb in p;
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
            /get first avail hdb
            avail:gwHandle"exec first where not inuse from .gw.servers where servertype=`hdb";
            hdbresult:value[hdbHandles][avail]@hdbquery;
            ];
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

// Error checks
/ time range is today, procs is hdb - no overlap
error1:`tablename`starttime`endtime`instruments`columns`procs!(`trade;today;today;syms2;tradecols;`hdb)
/ wrong procs name specified
error2:`tablename`starttime`endtime`instruments`columns`procs!(`trade;today;today;syms2;tradecols;`wdb)
/ return error if any freeform queries is going to any striped database, i.e. full striped
/ partial and no striped cases should not return error
error3:`tablename`starttime`endtime`freeformby`aggregations`freeformwhere!(`quote;hdbdate+0D;now;"sym";(`max`min)!((`ask`bid);(`ask`bid));"sym in `AMD`HPQ`DOW`MSFT`AIG`IBM")

error:{[gwHandle;rdbHandles;querydict]
	/trap the error (if any) for checks
    trap:@[gwHandle;(`.dataaccess.getdata;error1);{x}];
    if[trap like "*no info found for that table name and time range*";:1b];
    if[trap like "*wouldn't have otherwise been queried by the processe*";:1b];
    s:rdbHandles@\:".rdb.subfiltered";
	/if all striped - check if error is correct
	/partial and no striped cases will not result in an error
    if[all s;:trap like "*Freeform queries are not allowed as the data is striped*"];
    :98h~type trap;
    }
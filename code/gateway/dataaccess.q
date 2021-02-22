\d .dataaccess

timebarmap:`nanosecond`timespan`microsecond`second`minute`hour`day!1 1 1000 1000000000 60000000000 3600000000000 86400000000000;

// function to convert sorting
go:{if[`asc=x[0];:(xasc;x[1])];:(xdesc;x[1])};

// Full generality dataaccess function in the gateway
// Projections defined similarly to .gw.(a)syncexec(j/p/t)
// Main Function is .dataaccess.(a)getdata
getdata:{[o]
    // Input checking in the gateway
    o:.checkinputs.checkinputs[o];
    // Default queryoptimisation to true
    if[not `queryoptimisation in key o;o[`queryoptimisation]:1b];
    // Get the Procs
    o[`procs]:attributesrouting[o;partdict[o]];
    // Log the requests
    .requests.logger[o;()];
    // Get Default process behavior
    default:`join`timeout`postback!(multiprocjoin[o];0Wn;());
    // Use upserting logic to determine behaviour
    options:default^o;
    options[`ordering]: go each options`ordering;
    // Execute the queries
    $[.gw.call .z.w;
        //if sync
        :.gw.syncexecjt[(`getdata;o);options[`procs];{tab::(x[`join])[y];: {.[y;(z;x)]}/[tab;(x[`ordering])[;0];(x[`ordering])[;1]]}[options];options[`timeout]];
        // if async
        :.gw.asyncexecjpt[(`getdata;o);options[`procs];{tab::(x[`join])[y];: {.[y;(z;x)]}/[tab;(x[`ordering])[;0];options[`postback];options[`timeout]]];
    };

// Dynamic routing finds all processes with relevant data 
attributesrouting:{[options;procdict]
    // Get the tablename and timespan
    timespan:`date$options[`starttime`endtime];
    // See if any of the provided partitions are with the requested ones
    procdict:{[x;timespan] (all x within timespan) or any timespan within x}[;timespan] each procdict;
    // Only return appropriate dates
    types:(key procdict) where value procdict;
    // If the dates are out of scope of processes then error
    if[0=count types;
        '`$"gateway error - no info found for that table name and time range. Either table does not exist; attributes are incorect in .gw.servers on gateway, or the date range is outside the ones present"
       ];
    :types;
    };

// Generates a dictionary of `tablename!mindate;maxdate
partdict:{[input]
    tabname:input[`tablename];
    // extract the procs which have the table defined
    servers:select from .gw.servers where {[x;tabname]tabname in @[x;`tables]}[;tabname] each attributes;
    // Create a dictionary of the attributes against servertypes
    procdict:(exec servertype from servers)!(exec attributes from servers)@'(key each exec attributes from servers)[;0];
    // If the response is a dictionary index into the tablename
    procdict:@[procdict;key procdict;{[x;tabname]if[99h=type x;:x[tabname]];:x}[;tabname]];
    // returns the dictionary as min date/ max date
    :@[procdict;key procdict;{:(min x; max x)}]
    };

// Default dataaccess join allowing for aggregations across processes
multiprocjoin:{[input]
    //If there is only one proc queried output the table
    if[1=count input `procs;:{::}];
    // If no aggregations key is provided return a basic raze function
    if[not `aggregations in key input;:raze];
    // If a by date clause has been added then just raze as normal
    if[`grouping in key input;if[`date in input[`grouping];:raze]];
    // If timebar is called just error
    if[`timebar in key input;$[(((input[`timebar][0])*.dataaccess.timebarmap[input[`timebar][1]]) xbar 00:00:00.0+lastrollover[])=00:00:00.0+lastrollover[];:raze;'`$"Can't have a cross process timebar not land directly on the rollover try adding a date grouping"]];
    // If user queries for an aggregation which isn't allowed cross process error
    if[not all (key input[`aggregations]) in key crossprocfunctions;'`$"Can't use the following aggregations across processes avg, cor, cov, dev, med, var, wavg, wsum consider adding a date grouping"];
    :crossprocmerge[input;];
    };

// Extract a column from a table maintaining the keys if applicable
colextract:{[x;y]?[x;();$[x~0!x;0b;(cols key x)!cols key x];(enlist y)!enlist y]};

//list of accepted functions
crossprocfunctions:`count`distinct`first`last`max`min`prd`sum!(sum;distinct;first;last;max;min;prd;sum);

colmerge:{[f;A;z] crossprocfunctions[f] (colextract[;z]) each A};

// Extract list of crossproc aggregations to be used
colstm:{[input]: raze ((count') input[`aggregations]) #' key input[`aggregations]};

// Merge the tables
crossprocmerge:{[input;A](^/)colmerge[;A;]'[colstm[input];$[A[0]~0!A[0];cols A[0];((cols A[0]) where not (cols A[0]) in  cols key A[0])]]};
\d .

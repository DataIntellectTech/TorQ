\d .dataaccess

forceservers:0b;

// function to convert sorting
go:{if[`asc=x[0];:(xasc;x[1])];:(xdesc;x[1])};

// Full generality dataaccess function in the gateway
getdata:{[o]
    // Input checking in the gateway
    reqno:.requests.initlogger[o];
    o:@[.checkinputs.checkinputs;o;.requests.error[reqno]];
    // Get the Procs
    if[not `procs in key o;o[`procs]:attributesrouting[o;partdict[o]]];
    // Get Default process behavior
    default:`join`timeout`postback`sublist`getquery`queryoptimisation`postprocessing!(multiprocjoin[o];0Wn;();0W;0b;1b;{:x;});
    // Use upserting logic to determine behaviour
    options:default,o;
    if[`ordering in key o;options[`ordering]: go each options`ordering];
    o:adjustqueries[o;partdict o];
    // Execute the queries
    if[options`getquery;
        $[.gw.call .z.w;
            :.gw.syncexec[(`.dataaccess.buildquery;o);options[`procs]];
            :.gw.asyncexec[(`.dataaccess.buildquery;o);options[`procs]]]];
    $[.gw.call .z.w;
        //if sync
        :.gw.syncexecjt[(`getdata;o);options[`procs];returntab[options;;reqno];options[`timeout]];
        // if async
        :.gw.asyncexecjpt[(`getdata;o);options[`procs];returntab[options;;reqno];options[`postback];options[`timeout]]];
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
// mixture of all the post processing functions in gw
returntab:{[input;tab;reqno]
    joinfn:input[`join];
    // Join the tables together with the join function
    tab:joinfn[tab];
    // Sort the joined table in the gateway
    if[`ordering in key input;tab:{.[y;(z;x)]}/[tab;(input[`ordering])[;0];(input[`ordering])[;1]]];
    // Return the sublist from the table then apply the post processing function
    tab:select [input`sublist] from tab;
    // Undergo post processing
    tab:(input[`postprocessing])[tab];
    // Update the logger
    .requests.updatelogger[reqno;`endtime`success!(.proc.cp[];1b)];
    :tab
    };


// Generates a dictionary of `tablename!mindate;maxdate
partdict:{[input]
    tabname:input[`tablename];
    // Remove duplicate servertypes from the gw.servers
    servers:select from .gw.servers where i=(first;i)fby servertype;
    // extract the procs which have the table defined
    servers:select from servers where {[x;tabname]tabname in @[x;`tables]}[;tabname] each attributes;
    // Create a dictionary of the attributes against servertypes
    procdict:(exec servertype from servers)!(exec attributes from servers)@'(key each exec attributes from servers)[;0];
    // If the response is a dictionary index into the tablename
    procdict:@[procdict;key procdict;{[x;tabname]if[99h=type x;:x[tabname]];:x}[;tabname]];
    // returns the dictionary as min date/ max date
    procdict:asc @[procdict;key procdict;{:(min x; max x)}];
    // prevents overlap if more than one process contains a specified date
    if[1<count procdict;
        procdict:{:$[y~`date$();x;$[within[x 0;(min y;max y)];(1+max[y];x 1);x]]}':[procdict]];
    :procdict;
    };

// function to adjust the queries being sent to processes to prevent overlap of
// time clause and data being queried on more than one process
adjustqueries:{[options;part]
    // if only one process then no need to adjust
    if[2>count p:options`procs;:options];
    // get the date casting where relevant
    st:$[a:-14h~tp:type start:options`starttime;start;`date$start];
    et:$[a;options`endtime;`date$options`endtime];
    // get the dates that are required by each process
    dates:group key[part]where each{within[y;]each value x}[part]'[l:st+til 1+et-st];
    dates:l{(min x;max x)}'[dates];
    // if start/end time not a date, then adjust dates parameter for the
    // correct types
    if[not a;
        // converts dates dictionary to timestamps/datetimes
        dates:$[-15h~tp;{"z"$x};::]{(0D+x 0;x[1]+1D-1)}'[dates];
        // convert first and last timestamp to start and end time
        dates:@[dates;f;:;(start;dates[f:first key dates;1])];
        dates:@[dates;l;:;(dates[l:last key dates;0];options`endtime)]];
    // create a dictionary of procs and different queries
    :{@[@[x;`starttime;:;y 0];`endtime;:;y 1]}[options]'[dates];
    };

// Default dataaccess join allowing for aggregations across processes
multiprocjoin:{[input]
    //If there is only one proc queried output the table
    if[1=count input `procs;:{::}];
    // If no aggregations key is provided return a basic raze function
    if[not `aggregations in key input;:raze];
    // If a by date clause has been added then just raze as normal
    if[`grouping in key input;if[`date in input[`grouping];:raze]];
    // If timebar is called check it lines up with rollover
    if[`timebar in key input;$[(((input[`timebar][0])*.dataaccess.timebarmap[input[`timebar][1]]) xbar 00:00:00.0+.dacustomfuncs.lastrollover[input[`tablename]])=00:00:00.0+.dacustomfuncs.lastrollover[input[`tablename]];:raze;'`$"Can't have a cross process timebar not land directly on the rollover try adding a date grouping"]]; 
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

updategwtabprop:{[]:.gw.syncexec[".checkinputs.tablepropertiesconfig";exec servertype from .gw.servers];}

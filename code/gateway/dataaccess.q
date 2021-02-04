system "l ",getenv[`KDBCODE],"/dataaccess/customfuncs.q";
\d .dataaccess
timebarmap:`nanosecond`timespan`microsecond`second`minute`hour`day!1 1 1000 1000000000 60000000000 3600000000000 86400000000000;
// All queries have initial checks performed then sent to the correct processes
syncexec:{[o] .checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexec[(`getdata;o);datesrouting[o]]};
syncexecj:{[o;j] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecj[(`getdata;o);datesrouting[o];j]};
syncexecjt:{[o;j;t] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecjt[(`getdata;o);datesrouting[o];j;t]};
syncexecs:{[o;s] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexec[(`getdata;o);s]};
syncexecsj:{[o;s;j] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecj[(`getdata;o);s;j]};
syncexecsjt:{[o;s;j;t] o:.checkinputs.checkinputs[o];.requests.logger[o;()];.gw.syncexecjt[(`getdata;o);s;j;t]};

// Main dataaccess function in the gateway
getdata:{[o]
    // Check the inputs before they hit the gateway 
    o:.checkinputs.checkinputs[o];
    // Log the request
    .requests.logger[o;()];
    // Get the process to query
    procs:datesrouting[o];
    // Add the proc list to the query
    o[`procs]:procs;
    :.gw.syncexecj[(`getdata;o);procs;multiprocjoin[o]];
    };

// Decides which processes send the query to 
datesrouting:{[input]
    //Get the start and end time
    timespan:input[`starttime`endtime];
    // Get most recent Rollover
    rollover:lastrollover[];
    :@[`hdb`rdb;where(timespan[0]<rollover;timespan[1]>rollover)];
    };

// Default dataaccess join allowing for aggregations across processes
multiprocjoin:{[input]
    //If there is only one proc queried output the table
    if[1=count input `procs;:{::};];
    // If no aggregations key is provided return a basic raze function
    if[not `aggregations in key input;:raze];
    // If a by date clause has been added then just raze as normal
    if[`grouping in key input;if[`date in input[`grouping];:raze]];
    // If timebar is called just error
    if[`timebar in key input;$[(((input[`timebar][0])*.dataaccess.timebarmap[input[`timebar][1]]) xbar 00:00:00.0+lastrollover[])=00:00:00.0+lastrollover[];:raze;'`$"Can't have a cross process timebar not land directly on the rollover try adding a date grouping"]];
    // If user queries for an aggregation which isn't allowed cross process error
    if[not all (key input[`aggregations]) in key crossprocfunctions;'`$"Can't use the following aggregations across processes avg, cor, cov, dev, med, var, wavg, wsum consider adding a date grouping"];
    :crossprocmerge[input;]
    };

// Extract a column from a table maintaining the keys if applicable
colextract:{[x;y]?[x;();$[x~0!x;0b;(cols key x)!cols key x];(enlist y)!enlist y]};

// list of accepted functions
crossprocfunctions:`count`distinct`first`last`max`min`prd`sum!(sum;distinct;first;last;max;min;prd;sum);

// join a list of tables using function f
colmerge:{[f;A;z] crossprocfunctions[f] (colextract[;z]) each A};

// Extract list of crossproc aggregations to be used
colstm:{[input]: raze ((count') input[`aggregations]) #' key input[`aggregations]};

// Merge the tables
crossprocmerge:{[input;A]colmerge[;A;]'[colstm[input];$[A[0]~0!A[0];cols A[0];((cols A[0]) where not (cols A[0]) in  cols key A[0])]]};

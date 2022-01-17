\d .dataaccess

forceservers:0b;

// dictionary containing aggregate functions needed to calculate map-reducable
// values over multiple processes
aggadjust:(!). flip(
    (`avg;     {flip(`sum`count;2#x)});
    (`cor;     {flip(`wsum`count`sum`sum`sumsq`sumsq;@[x;(enlist(0;1);0;0;1;0;1)])});
    (`count;   `);
    (`cov;     {flip(`wsum`count`sum`sum;@[x;(enlist(0;1);0;0;1)])});
    (`dev;     {flip(`sumsq`count`sum;3#x)});
    (`distinct;`);
    (`first;   `);
    (`last;    `);
    (`max;     `);
    (`min;     `);
    (`prd;     `);
    (`sum;     `);
    (`var;     {flip(`sumsq`count`sum;3#x)});
    (`wavg;    {flip(`wsum`sum;(enlist(x 0;x 1);x 0))});
    (`wsum;    {enlist(`wsum;enlist(x 0;x 1))}));

// function to make symbols strings with an upper case first letter
camel:{$[11h~type x;@[;0;upper]each string x;@[string x;0;upper]]};
// function that creates aggregation where X(X1,X2)=X(X(X1),X(X2)) where X is
// the aggregation and X1 and X2 are non overlapping subsets of a list
absagg:{enlist[`$x,y]!enlist(value x;`$x,y)};

// functions to calculate avg, cov and var in mapaggregate dictionary
avgf:{(%;(sum;`$"sum",x);scx y)};
covf:{(-;(%;swsum[x;y];scx x);(*;avgf[x;x];avgf[y;x]))};
varf:{(-;(%;(sum;`$"sumsq",y);scx x);(xexp;avgf[y;x];2))};
// functions to sum counts and wsums in mapaggregate dictioanry
scx:{(sum;`$"count",x)};
swsum:{(sum;`$"wsum",x,y)}

// dictionary containing the functions needed to aggregate results together for
// map reducable aggregations
mapaggregate:(!). flip(
    (`avg;      {enlist[`$"avg",x]!enlist(%;(sum;`$"sum",x);scx x)});
    (`cor;      {enlist[`$"cor",x,w]!enlist(%;covf[x;w];(*;(sqrt;varf[x;x]);(sqrt;varf[(x:x 0);w:x 1])))});
    (`count;    {enlist[`$"count",x]!enlist scx x});
    (`cov;      {enlist[`$"cov",x,w]!enlist covf[x:x 0;w:x 1]});
    (`dev;      {enlist[`$"dev",x]!enlist(sqrt;varf[x;x])});
    (`first;    {enlist[`$"first",x]!enlist(*:;`$"first",x)});
    (`last;     {absagg["last";x]});
    (`max;      {absagg["max";x]});
    (`min;      {absagg["min";x]});
    (`prd;      {absagg["prd";x]});
    (`sum;      {absagg["sum";x]});
    (`var;      {enlist[`$"var",x]!enlist varf[x;x]});
    (`wavg;     {enlist[`$"wavg",x,w]!enlist(%;swsum[x:x 0;w:x 1];(sum;`$"sum",x))});
    (`wsum;     {enlist[`$"wsum",x,w]!enlist swsum[x:x 0;w:x 1]}));

// function to convert sorting
go:{if[`asc=x[0];:(xasc;x[1])];:(xdesc;x[1])};

// Full generality dataaccess function in the gateway
getdata:{[o]
    // Input checking in the gateway
    reqno:.requests.initlogger[o];
    o:@[.checkinputs.checkinputs;o;.requests.error[reqno]];
    // Get the Procs in a (nested) list of serverid(s)
    o[`procs]:attributesrouting[o;part:partdict o];
    // Get Default process behavior
    default:`timeout`postback`sublist`getquery`queryoptimisation`postprocessing!(0Wn;();0W;0b;1b;{:x;});
    // Use upserting logic to determine behaviour
    options:default,o;
    if[`ordering in key o;options[`ordering]: go each options`ordering];
    o:adjustqueries[o;part];
    // Check if any freeform queries is going to any striped database
    if[exec count serverid from .gw.servers where({all`skeysym`skeytime in key x}each attributes)&serverid in first each key o;
        if[any key[options]like"*freeform*";
                '`$.schema.errors[`freeformstripe;`errormessage];
            ];
        ];
    options[`mapreduce]:0b;
    gr:$[`grouping in key options;options`grouping;`];
    if[`aggregations in key options;
        if[all key[options`aggregations]in key aggadjust;
            options[`mapreduce]:not`date in gr]];
    // Execute the queries
    if[options`getquery;
        $[.gw.call .z.w;
            :.gw.syncexec[(`.dataaccess.buildquery;o);options[`procs]];
            :.gw.asyncexec[(`.dataaccess.buildquery;o);options[`procs]]]];
    :$[.gw.call .z.w;
        //if sync
        .gw.syncexecjt[(`getdata;o);options[`procs];autojoin[options];options[`timeout]];
        // if async
        .gw.asyncexecjpt[(`getdata;o);options[`procs];autojoin[options];options[`postback];options[`timeout]]];
    };


// join results together if from multiple processes
autojoin:{[options]
    // if there is only one proc queried output the table
    if[1=count options`procs;:first];
    // if there is no need for map reducable adjustment, return razed results
    if[not options`mapreduce;:raze];
    :mapreduceres[options;];
    };

// function to correctly reduce two tables to one
mapreduceres:{[options;res]
    // raze the result sets together
    res:$[all 99h=type each res;
        (){x,0!y}/res;
        (),/res];
    aggs:options`aggregations;
    aggs:flip(key[aggs]where count each value aggs;raze aggs);
    // distinct may be present as only agg, so apply distinct again
    if[all`distinct=first each aggs;:?[res;();1b;()]];
    // collecting the appropriate grouping argument for map-reduce aggs
    gr:$[all`grouping`timebar in key options;
            a!a:options[`timebar;2],options`grouping;
        `grouping in key options;
            a!a:(),options`grouping;
        `timebar in key options;
            a!a:(),options[`timebar;2];
            0b];
    // select aggs by gr from res
    :?[res;();gr;raze{mapaggregate[x 0;camel x 1]}'[aggs]];
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
    // Get the servers
    servers:update striped:{all`skeysym`skeytime in key x}each attributes from .gw.servers;
    // Filter the servers by servertype input
    if[`procs in key input;select from servers where servertype in input`procs];
	// Servertypes that are all striped
    allstriped:select from servers where(all;striped)fby servertype;
    // Servertypes that has any but not all striped
    // Sort it by serverid
    anyandnotallstriped:select by serverid from servers 
        where((striped=0)&({any[x]&not all x};striped)fby servertype)|not(any;striped)fby servertype;
    servers:allstriped,
        // Get the first unstriped server by type
        select from anyandnotallstriped where i=(first;i)fby servertype;
    // Get the (nested) list of serverids by servertype
    serverids:(exec serverid from allstriped),value exec serverid by servertype from anyandnotallstriped;
    // Create a dictionary of the attributes against serverids
    procdict:serverids!(servers'[first each serverids]`attributes)@\:`date;
    // Dictionary as min date/ max date
    procdict:@[procdict;key procdict;{:(min x; max x)}];
    // If procs is explicitly specified in input request, filter to only those procs
    if[(11h~type(),p:input`procs)&`procs in key input;
        overlap:all each key[procdict]in\:exec serverid from .gw.servers where servertype in p;
        procdict:key[procdict][w]!value[procdict]w:where overlap];
    :procdict;
    };

// function to adjust the queries being sent to processes to prevent overlap of
// time clause and data being queried on more than one process
adjustqueries:{[options;part]
	// Get the overlapping part(itions) from options`procs found by attributesrouting
	// e.g. if `procs is not specified in the querydict but starttime and endtime specified is .z.d
	//      attributesrouting will set options`procs to only rdb servers but part may still contain hdb servers
	overlap:max{x~/:key y}[;part]each options`procs;
	part:key[part][where overlap]!value[part]where overlap;
	// get the date casting where relevant
	st:$[a:-14h~tp:type start:options`starttime;start;`date$start];
	et:$[a;options`endtime;`date$options`endtime];
	// get the dates that are required by each process
	dates:key[part]!{y(min;max)@\:x}[;l]each where each flip{within[y;]each value x}[part]'[l:st+til 1+et-st];
	// if start/end time not a date, then adjust dates parameter for the
	// correct types
	if[not a;
		// converts dates dictionary to timestamps/datetimes
		dates:$[-15h~tp;{"z"$x};::]{(0D+x 0;x[1]+1D-1)}'[dates];
		// convert first and last timestamp to start and end time
		dates:key[dates]!?[value[dates][;0]<start;start;value[dates][;0]],'?[value[dates][;1]>end;end:options`endtime;value[dates][;1]];
		];
	// adjust map reducable aggregations to get correct components
	if[(1<count dates)&`aggregations in key options;
		if[all key[o:options`aggregations]in key aggadjust;
			aggs:mapreduce[o;$[`grouping in key options;options`grouping;`]];
			options:@[options;`aggregations;:;aggs]]];
	// create a dictionary of procs and different queries
	query:{@[@[x;`starttime;:;y 0];`endtime;:;y 1]}[options]'[dates];
	// adjust query if instruments given
	if[`instruments in key options;
		modquery:select serverid,{x`skeysym`skeytime}each attributes from .gw.servers where({all`skeysym`skeytime in key x}each attributes)&serverid in raze key part;
		querytable:0!(`serverid xkey update serverid:(first each key query)from value query)uj`serverid xkey modquery;
		// modify starttime, endtime and instruments based on stripe
		querytable:update
			{$[z;y;$[(stripest:x[1]0)<`time$y;y;stripest+`date$y]]}[;;a]'[attributes;starttime],
			{$[z;y;$[(stripeet:x[1]1)<`time$y;stripeet+`date$y;y]]}[;;a]'[attributes;endtime],
			// query instruments needs to be an atom if only 1sym is queried, if not it will throw a type error
			adjinstruments:{$[1=count s:skeysym where(skeysym:.ds.stripe[(),y;x 0])in y;s 0;s]}'[attributes;instruments]
				from querytable where serverid in modquery`serverid;
		querytable:update adjinstruments:instruments from querytable where not serverid in modquery`serverid;
		querytable:(enlist[`adjinstruments]!enlist `instruments)xcol enlist[`instruments]_querytable;
		// convert serverid atoms into their respective serverid lists
        querytable:update serverid:{x where{any x in y}[;y]each x}[options`procs;serverid],
            // get servertype
            servertype:`${string .gw.servers'[x]`servertype}serverid,
            // convert procs into procname if striped
            procs:`${string[.gw.servers[x]`servertype],string y+1}'[serverid;attributes[;0]]from 
                // filter queries not required
                select from querytable where 0<count each instruments;
        // return query as a dict of table
        :(exec serverid from querytable)!querytable;
		];
	// Input dictionary must have keys of type 11h
	:key[query]!update procs:.gw.servers'[first each key query]`servertype from value query;
	};

// function to grab the correct aggregations needed for aggregating over
// multiple processes
mapreduce:{[aggs;gr]
    // if there is a date grouping any aggregation is allowed
    if[`date in gr;:aggs];
    // format aggregations into a paired list
    aggs:flip(key[aggs]where count each value aggs;raze aggs);
    // if aggregations are not map-reducable and there is no date grouping,
    // then error
    if[not all aggs[;0]in key aggadjust;
        '`$"to perform non-map reducable aggregations automatically over multiple processes there must be a date grouping"];
    // aggregations are map reducable (with potential non-date groupings)
    aggs:distinct raze{$[`~a:.dataaccess.aggadjust x 0;enlist x;a x 1]}'[aggs];
    :first'[aggs]!last'[aggs];
    };

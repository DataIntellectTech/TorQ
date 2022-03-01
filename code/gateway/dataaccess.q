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
    // Get the procs in a (nested) list of serverid(s)
    o[`procs]:.gw.attributesrouting[o;part:.gw.partdict o];
    // Get Default process behavior
    default:`timeout`postback`sublist`getquery`optimisation`postprocessing!(0Wn;();0W;0b;1b;{:x;});
    // Use upserting logic to determine behaviour
    options:default,o;
    k:key o;
    if[`ordering in k;options[`ordering]: go each options`ordering];
    // Instruments wildcard (`)
    if[(`~o`instruments)&`instruments in key o;o _: `instruments];
    o:adjustqueries[o;part];
    // Check if any freeform queries is going to any striped database
    if[exec count serverid from .gw.servers where({`dataaccess in key x}each attributes)&serverid in first each key o;
        if[any key[options]like"*freeform*";
            if[not`instruments in key options;'`$.schema.errors[`freeformstripe;`errormessage]];
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

// Adjust queries based on relevant data and stripe
adjustqueries:{[options;part]
    // Get the overlapping part(itions) from options`procs found by attributesrouting
	dict:.gw.adjustqueriesoverlap[options;part];
	// adjust map reducable aggregations to get correct components
	if[(1<count dict`dates)&`aggregations in key options;
		if[all key[o:options`aggregations]in key aggadjust;
			aggs:mapreduce[o;$[`grouping in key options;options`grouping;`]];
			options:@[options;`aggregations;:;aggs]]];
    // Modify queries based on striped processes
    // Return query as a dict of table
	:.gw.adjustqueriesstripe[options;dict];
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
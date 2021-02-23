//- Script to load in custom functionality:
//- Useful for splitting queries 

\d .dacustomfuncs

//- (i) rollover
//- Function to determine which partitions the getdata function should query
//- e.g If the box is based in Paris (GMT+01:00) and rollover is at midnight London time then tzone:-01:00 
//- e.g If the box is UTC based and rollover is at 10pm UTC then rover: 22:00

rollover:{[tabname;hdbtime;prc]
    // Extract the TimeStamps relative to local
    A:?[.checkinputs.tablepropertiesconfig;((=;`tablename;(enlist tabname));(=;`proctype;(enlist prc)));();`rover`pfield`tzone!`rollovertime`partitionfield`timezone];
    // Output
    A:first each A;
    :(A[`pfield]$hdbtime)+(A[`tzone]+A[`rover])>`minute$hdbtime;
    };

//- (ii) getpartitionrange
//- offset times for non-primary time columns
// example @[`date$(starttime;endtime);1;+;not `time~`time]

partitionrange:{[tabname;hdbtimerange;prc;timecol]
    // Get the partition fields from default rollover 
    hdbtimerange:rollover[tabname;;prc] each hdbtimerange;
    C::?[.checkinputs.tablepropertiesconfig;((=;`tablename;(enlist tabname));(=;`proctype;(enlist prc)));();(1#`ptc)!1#`primarytimecolumn];
    // Output the partitions allowing for non-primary timecolumn
    :@[hdbtimerange;1;+;any timecol=raze C[`ptc]]};

// Gets the last rollover
lastrollover:{:rollover[x;.proc.cp[];.proc.proctype]};

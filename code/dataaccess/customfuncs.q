//- Script to load in custom functionality:
//- Useful for splitting queries 

\d .dacustomfuncs

//- (i) rollover
//- Function to determine which partitions the getdata function should query
//- e.g If the box is based in Paris (GMT+01:00) and rollover is at midnight London time then tzone:-01:00 
//- e.g If the box is UTC based and rollover is at 10pm UTC then rover: 22:00
rollover:{[tabname;hdbtime;prc]
    // Extract the data from tableproperties.csv
    A:?[.checkinputs.tablepropertiesconfig;((=;`tablename;(enlist tabname));(=;`proctype;(enlist prc)));();`rolltimeoffset`rolltimezone`datatimezone`partitionfield!`rolltimeoffset`rolltimezone`datatimezone`partitionfield];
    // Output
    A:first each A;
    // Get the hdbtime adjustment
    adjroll::exec adjustment from .tz.t asof `timezoneID`localDateTime!(A[`rolltimezone];hdbtime);
    // convert rolltimeoffset from box timezone -> utc
    rolltimeUTC:`time$A[`rolltimeoffset]+adjroll;
    // convert from data timezone -> utc
    adjdata:exec adjustment from .tz.t asof `timezoneID`gmtDateTime!(A[`datatimezone];hdbtime+adjroll);
    querytimeUTC:`time$hdbtime+$[0Nn~adjdata;00:00;adjdata];
    $[querytimeUTC >= rolltimeUTC;:A[`partitionfield]$hdbtime;:offsetbyone[hdbtime;A[`partitionfield]]];              
    };

//- (ii) getpartitionrange
//- offset times for non-primary time columns
// example @[`date$(starttime;endtime);1;+;not `time~`time]
partitionrange:{[tabname;hdbtimerange;prc;timecol]
    // Get the partition fields from default rollover 
    hdbtimerange:rollover[tabname;;prc] each hdbtimerange+00:00;
    C:?[.checkinputs.tablepropertiesconfig;((=;`tablename;(enlist tabname));(=;`proctype;(enlist prc)));();(1#`ptc)!1#`primarytimecolumn];
    // Output the partitions allowing for non-primary timecolumn
    :@[hdbtimerange;1;+;any timecol=raze C[`ptc]]};

// Gets the last rollover
lastrollover:{:rollover[x;.proc.cp[];`hdb]};

offsetbyone:{[time;pfield]
    if[pfield~`date;:`date$time-1D];
    if[pfield~`month;:.Q.addmonths[time;-1]];
    :(`year$time)-1;
    };

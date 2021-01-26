//- Script to load in custom functionality:
//- see getrollover/getpartitionrange in config/tableproperties.csv

\d .dataaccess

// Rollover in localtime
rollover:00:00;

//- (i) getrollover
//- Function to determine which partitions the getdata function should query
//- e.g If the box is based in Paris +01:00 and rollover is at midnight  London time then tzone:-01:00 
//- e.g If the box is UTC based and rollover is at 10pm UTC then rover: 22:00

defaultrollover:{[partitionfield;hdbtime;tzone;rover]
    // If no time zone argument is supplied then just assume the stamps are in local time
    if[tzone~`;tzone:00:00];
    //Return the partition 
    :(partitionfield$hdbtime)+(tzone+rover)>`minute$hdbtime};

//- (ii) getpartitionrange
//- offset times for non-primary time columns
// example @[`date$(starttime;endtime);1;+;not `time~`time]

defaultpartitionrange:{[timecolumn;primarytimecolumn;partitionfield;hdbtimerange;rolloverf;timezone]
    // Get the partition fields from default rollover 
    hdbtimerange:partitionfield rolloverf[;;timezone;rollover]/: hdbtimerange;
    // Output the partitions allowing for non-primary timecolumn
       :@[hdbtimerange;1;+;not timecolumn~primarytimecolumn]};

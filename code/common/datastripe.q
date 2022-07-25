// stripe data across rdbs

\d .ds

// Casting segid to symbol to enable free naming of segments
// segmentid taken from -segid process parameter
segmentid:`$.proc.params[`segid];


tablekeycolsconfig:@[value;`.ds.tablekeycolsconfig;`tablekeycols.csv];    // getting the location of the tablekeycols.csv config file

loadtablekeycols:{[]                                                          // loading the tablekeycols config as a dictionary
    keypath:first .proc.getconfigfile[string .ds.tablekeycolsconfig];
    @[{tablekeycols:(!/)(("SS";enlist",")0: hsym x)`tablename`keycol};keypath;{.lg.e[`init;"Failure in loading ",string y]}[;keypath]]
    };

getstarttime:{[x] $[0Wp~min x[`time];0Np;min x[`time]]};
getendtime:{[x] max x[`time]};

// function to clear tables before given time
deletetablebefore:{![x;enlist (<;y;z);0b;0#`]}

//Function to check if a segid is defined if datastriping is on
checksegid:{if[datastripe;if[not (`segid in key .proc.params);.lg.e[`init;"Datastriping is turned on however no segment id has been defined for this process"]]]}

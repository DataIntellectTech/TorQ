\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values

\d .

loadtablekeycols:{[]
    keypath:first .proc.getconfigfile["tablekeycols.csv"];
    @[{.ds.tablekeycols:(!/)(("SS";enlist",")0: hsym x)`tablename`keycol};keypath;{.lg.e[`init;"Failure in loading ",string y]}[;keypath]];
    };


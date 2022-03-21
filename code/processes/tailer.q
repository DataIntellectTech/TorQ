keyload:{
    keypath:first .proc.getconfigfile[string `keycols.csv];
    @[{keydict:(!/)(("SS";enlist",")0: hsym x)`tablename`keycol};keypath;{.lg.e[`init;"Failure in loading ",string y]}[;keypath]];
    };

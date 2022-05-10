// stripe data across rdbs

\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values


tablekeycolsconfig:@[value;`.ds.tablekeycolsconfig;`tablekeycols.csv];    // getting the location of the tablekeycols.csv config file

loadtablekeycols:{[]                                                          // loading the tablekeycols config as a dictionary
    keypath:first .proc.getconfigfile[string .ds.tablekeycolsconfig];
    @[{tablekeycols:(!/)(("SS";enlist",")0: hsym x)`tablename`keycol};keypath;{.lg.e[`init;"Failure in loading ",string y]}[;keypath]]
    };

getstarttime:{[x] first x[`time]};

deletetablebefore:{![x;enlist (<;y;z);0b;0#`]}

\d .

initdatastripe:{
	// update endofday and endofperiod functions
    endofday::.rdb.endofday;
    /endofperiod::.rdb.datastripeendofperiod;
    };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

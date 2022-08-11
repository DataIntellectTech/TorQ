// stripe data across rdbs

\d .ds

segmentid: "J"$.proc.params[`segid]		// segmentid variable defined by applying key to dictionary of input values


tablekeycolsconfig:@[value;`.ds.tablekeycolsconfig;`tablekeycols.csv];    // getting the location of the tablekeycols.csv config file

loadtablekeycols:{[]                                                          // loading the tablekeycols config as a dictionary
    keypath:first .proc.getconfigfile[string .ds.tablekeycolsconfig];
    @[{tablekeycols:(!/)(("SS";enlist",")0: hsym x)`tablename`keycol};keypath;{.lg.e[`init;"Failure in loading ",string y]}[;keypath]]
    };

getstarttime:{[x] $[0Wp~min x[`time];0Np;min x[`time]]};
getendtime:{[x] max x[`time]};

// function to clear tables before given time
deletetablebefore:{![x;enlist (<;y;z);0b;0#`]}

// function to filter replayed tables with where clause from striping.json
applyfilters:{[filtertab;td]
  if[count filtertab;
   .lg.o[`subscribe;"filtering table(s) ", (", " sv string filtertab), " started at: ",string .z.P];
   set'[filtertab; filtertable[;td] each filtertab];
   .lg.o[`subscribe;"finished filtering table(s) ", (", " sv string filtertab), " at: ",string .z.P];
    ];
  }

// function to apply datastriping filter from a filter dictionary to a table
filtertable:{[filtertab;td]
  filterparse:@[parse;"exec from x where ", td[filtertab]];
  {eval(?;x;y[2];0b;())}[filtertab;filterparse]
  }

filterreplayed:{[lf;td;logmetatab]
  // lf is a log file handle and td is a dictionary with table names as keys and where clauses to filter by as values
  // logmetatab is the tplog metadata table loaded into the stp from the tplogs directory
    .lg.o[`subscribe;"replaying log file ",.Q.s1 lf]; -11!lf;
  // checks if the log file contains a table that requires filtering
    filtertab:(key td) inter raze exec tbls from logmetatab where logname=@[lf;1];
  // filters tables replayed by the logs if required
    if[count filtertab;applyfilters[filtertab;td]];
    };


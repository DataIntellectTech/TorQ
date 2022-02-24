//Defining a function that loads configurable .csv files into memory so relevant filters can be applied to data.

//calls segmenting.csv which customer edits as to how many segments there will be.
//calls filtermap.csv which customer edits as to what filters should be applied to each segment.

//configload transfoms segmenting.csv into table format so it can be accessed.
//configload transforms filtermap.csv into table format then into a mapping of wcRef to filter which can be accessed and applied to data.

//creating empty versions of segmenting table and filter mapping so we can revert to default mode if issues with either csv.

.stpps.segmentconfig:([] table:`$();segmentID:`int$();wcRef:`$());
.stpps.segmentfiltermap:enlist[`$()]!enlist[""];

//.lg.o being used for error message instead of .le.e at the moment to allow Adam to test if empty tables will cause the TP to default mode.
//.ds.filtermap/segmentconfig are variables which can take different csv files. These files can be chosen on the command line with the extras flag. The default variables are defined in segmentedtp.q.
//error trap these .ds variables incase this file is loaded stand alone.

.ds.segmentconfig:@[value;`.ds.segmentconfig;`segmenting.csv];
.ds.filtermap:@[value;`.ds.filtermap;`filtermap.csv];

configload:{
     @[{.stpps.segmentconfig:{("SIS";enlist",")0: hsym first .proc.getconfigfile[string x]}[x]};.ds.segmentconfig;{.lg.o[`init;"Failed to load segmenting.csv"]}];
     @[{.stpps.segmentfiltermap:{(!/)(("S*";enlist",")0: hsym first .proc.getconfigfile[string x])`wcRef`filter}[x]};.ds.filtermap;{.lg.o[`init;"Failed to load filtermap.csv"]}];
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

\d .stpps
//function to grab where clause from config tables
segmentfilter:{[tbl;segid]
  wcref:first exec wcRef from .stpps.segmentconfig where table=tbl , segmentID=segid;
  if[wcref~`;
    .lg.o["Invalid pairing of table ",string[tbl]," and segmentID ",string[segid],""]];
  .stpps.segmentfiltermap[wcref]
  };

  // Function to subscribe to particular segment using segmentID based on .u.sub
subsegment:{[tbl;segid];
//tablename and segmentid used to get filters
  if[tbl~`;:.z.s[;segid] each .stpps.t];
   if[not tbl in .stpps.t;
     .lg.e[`sub;m:"Table ",string[tbl]," not in list of stp pub/sub tables"];
     :(tbl;m)
  ];
  filter:segmentfilter[tbl;segid];
  if[filter~"";
    .lg.o[`sub;m:"Incorrect pairing of table ",string[tbl]," and segmentID ",string[segid]," not found in .stpps.segmentconfig"];
    :((tbl;segid);m)
  ];
 .ps.subtablefiltered[string[tbl];filter;""]
 };

\d .

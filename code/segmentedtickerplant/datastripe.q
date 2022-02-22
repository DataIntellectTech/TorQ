//Defining a function that loads configurable .csv files into memory so relevant filters can be applied to data

//calls segmenting.csv which customer edits as to how many segments there will be
//calls filtermap.csv which customer edits as to what filters should be applied to each segment

//function transfoms segmenting.csv into table format so it can be accessed
//function transforms filtermap.csv into table format then into a mapping of wcRef to filter which can be accessed and applied to data

configload:{
     .stpps.segmentconfig:("SIS";enlist",")0: hsym first .proc.getconfigfile["segmenting.csv"];
     .stpps.segmentfiltermap:(!/) (("SS";enlist",")0: hsym first .proc.getconfigfile["filtermap.csv"])`wcRef`filter;
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };

// Function to map the where clause from config table extracted by .stpps.segmentfilter function to tablename
// Allows use of ` as argument for tables

\d .stpps

filtermap:{[tabs;segid] if[tabs~`;tabs:.stpps.t]; ((),tabs)!.stpps.segmentfilter\:[(),tabs;segid]}

\d .


if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];



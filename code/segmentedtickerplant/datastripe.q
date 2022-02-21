//Defining a function that loads configurable .csv files into memory so relevant filters can be applied to data

//calls segmenting.csv which customer edits as to how many segments there will be
//calls filtermap.csv which customer edits as to what filters should be applied to each segment

//configload transfoms segmenting.csv into table format so it can be accessed
//configload transforms filtermap.csv into table format then into a mapping of wcRef to filter which can be accessed and applied to data

//creating empty versions of segmenting table and filter mapping so we can revert to default mode if issues with either csv

.stpps.segmentconfig:([] table:();segmentID:();wcRef:());
.stpps.segmentfiltermap:(!/)([] wcRef:();filter:())`wcRef`filter;

configload:{
     @[{.stpps.segmentconfig:{("SIS";enlist",")0: hsym first .proc.getconfigfile[x]}[x]};"segmenting.csv";{.lg.o[`stp1;"Failed to load segmenting.csv, revert to defaut mode and no segmenting."]}];
     @[{.stpps.segmentfiltermap:{(!/)(("SS";enlist",")0: hsym first .proc.getconfigfile[x])`wcRef`filter}[x]};"filtermap.csv";{.lg.o[`stp1;"Failed to load filtermap.csv, revert to defaut mode and no segmenting."]}]; 
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

//Defining a function that loads configurable .csv files into memory so relevant filters can be applied to data.
//calls segmenting.csv which customer edits as to how many segments there will be.
//calls filtermap.csv which customer edits as to what filters should be applied to each segment.

//.ds.segmentconfig/segmentfiltermap are variables which can take different csv files. These files can be chosen on in process.csv.
//error trap these .ds variables incase this file is loaded stand alone.

.ds.segmentconfig:@[value;`.ds.segmentconfig;`segmenting.csv];
.ds.filtermap:@[value;`.ds.filtermap;`filtermap.csv];

//if statements check segmenting.csv and filtermap.csv exist. If not, process exited and message sent to error logs.
//configload transfoms segmenting.csv into table format so it can be accessed.
//configload transforms filtermap.csv into table format then into a mapping of wcRef to filter which can be accessed and applied to data.
//checks csv files load correctly. If not, process exited and message sent to error logs.

configload:{
     if[()~key hsym scpath:first .proc.getconfigfile[string .ds.segmentconfig];.lg.e[`init;"The following file can not be found: ",string .ds.segmentconfig]];
     if[()~key hsym fmpath:first .proc.getconfigfile[string .ds.filtermap];.lg.e[`init;"The following file can not be found: ",string .ds.filtermap]];
     @[{.stpps.segmentconfig:("SIS";enlist",")0: hsym x};scpath;{.lg.e[`init;"Failure in loading ",string y]}[;scpath]];
     @[{.stpps.segmentfiltermap:(!/)(("S*";enlist",")0: hsym x)`wcRef`filter};fmpath;{.lg.e[`init;"Failure in loading ",string y]}[;fmpath]];
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };

// Function to map the where clause from config table extracted by .stpps.segmentfilter function to tablename
// Allows use of ` as argument for tables

\d .stpps

filtermap:{[tabs;id] if[tabs~`;tabs:.stpps.t]; ((),tabs)!.stpps.segmentfilter\:[(),tabs;id]}

// Find where clause from config tables
segmentfilter:{[tbl;segid]
     wcref:first exec wcRef from .stpps.segmentconfig where table=tbl , segmentID=segid;
     if[wcref~`;
          .lg.o["Invalid pairing of table ",string[tbl]," and segmentID ",string[segid],""]];
     .stpps.segmentfiltermap[wcref]
     };

// Subscribe to particular segment using segmentID based on .u.sub
subsegment:{[tbl;segid];
     //tablename and segmentid used to get filters
     if[tbl~`;:.z.s[;segid] each .stpps.t];
     if[not tbl in .stpps.t;
          .lg.e[`sub;m:"Table ",string[tbl]," not in list of stp pub/sub tables"];
          :(tbl;m)
     ];
     filter:segmentfilter[tbl;segid];
     if[filter~"";
          .lg.e[`sub;m:"Incorrect pairing of table ",string[tbl]," and segmentID ",string[segid]," not found in .stpps.segmentconfig"];
          :(tbl;m)
     ];
     .ps.subtablefiltered[string[tbl];filter;""]
     };

\d .

// the subdetails function adapted to also retrieve filters from the segmented tickerplant
segmentedsubdetails: {[tabs;instruments;segid] (!). flip 2 cut (
     `schemalist ; .stpps.subsegment\:[tabs;segid];                                 //
     `logfilelist ; .stplg.replaylog[tabs];                                         //
     `rowcounts ; tabrowcounts[tabs];	                                              //
     `date ; (.eodtime `d);                                                         //
     `logdir ; `$getenv`KDBTPLOG;                                                   //
     `filters ; .stpps.filtermap[tabs;segid]                                        //
     )}
        
if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];



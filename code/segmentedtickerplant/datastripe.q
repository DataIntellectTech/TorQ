//configload loads configurable .csv files into memory so relevant filters can be applied to data.
//loads segmenting.csv which defines how many segments there will be.
//loads filtermap.csv which defines what filters should be applied to each segment.

//.ds.segmentconfig/segmentfiltermap are variables which can take different csv files. These files can be chosen on in process.csv.
//error trap these .ds variables incase this file is loaded stand alone.

.ds.segmentconfig:@[value;`.ds.segmentconfig;`segmenting.csv];
.ds.filtermap:@[value;`.ds.filtermap;`filtermap.csv];
.ds.fullsubscriptions:@[value;`.ds.fullsubscriptions;`fullsubscriptions.csv];
.ds.ignoredtables:@[value;`.ds.ignoredtables;`ignoredtables.csv];

//if statement checks segmenting.csv and filtermap.csv exist. If not, process exited and message sent to error logs.
//configload transfoms segmenting.csv into table format so it can be accessed.
//configload transforms filtermap.csv into table format then into a mapping of wcRef to filter which can be accessed and applied to data.
//checks csv files load correctly. If not, process exited and message sent to error logs.

configload:{
     scpath:first .proc.getconfigfile[string .ds.segmentconfig];
     fmpath:first .proc.getconfigfile[string .ds.filtermap];
     {if[()~key hsym x;.lg.e[`init;"The following file can not be found: ",string x]]} each (scpath;fmpath);
     @[{.stpps.segmentconfig:("SIS";enlist",")0: hsym x};scpath;{.lg.e[`init;"Failure in loading ",string y]}[;scpath]];
     @[{.stpps.segmentfiltermap:(!/)(("S*";enlist",")0: hsym x)`wcRef`filter};fmpath;{.lg.e[`init;"Failure in loading ",string y]}[;fmpath]];
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };

\d .stpps

// Function to map the where clause from config table extracted by .stpps.segmentfilter function to tablename
// Allows use of ` as argument for tables
filtermap:{[tabs;id] if[tabs~`;tabs:.stpps.t]; ((),tabs)!.stpps.segmentfilter\:[(),tabs;id]}

// Find where clause from config tables
segmentfilter:{[tbl;segid]
     wcref:first exec wcRef from .stpps.segmentconfig where table=tbl , segmentID=segid;
     .stpps.segmentfiltermap[wcref]
     };

//Setting the path to the csv containing the tables that will not be segmented. Reading in the ignoredtables.csv
stpath:first .proc.getconfigfile[string .ds.fullsubscriptions];
[{.stpps.fullsubscriptions:("S ";enlist",")0: hsym x}.stpps.stpath];
igtpath:first .proc.getconfigfile[string .ds.ignoredtables];
[{.stpps.ignoredtables:("S ";enlist",")0: hsym x}.stpps.igtpath];


// Subscribe to particular segment using segmentID based on .u.sub
subsegment:{[tbl;segid];
     //tablename and segmentid used to get filters
     if[tbl~`;:.z.s[;segid] each .stpps.t];
     if[not tbl in .stpps.t;
          .lg.e[`sub;m:"Table ",string[tbl]," not in list of stp pub/sub tables"];
          :(tbl;`err`msg!(`table;m));
     ];
     filter:segmentfilter[tbl;segid];
     $[tbl in .stpps.fullsubscriptions;[.stpps.suball[tbl]];
     [$[tbl in .stpps.ignoredtables;
                    [.lg.o[`sub;m:"Table ",string[tbl]," is in ignoredtables.csv and will not be subscribed to"];
                    :();];
       $[filter~"";             
                    [.lg.e[`sub;m:"Incorrect pairing of table ",string[tbl]," and segmentID ",string[segid]," not found in .stpps.segmentconfig"];
                    :(tbl;`err`msg!(`segmentid;m));]
                    ;
                    [.ps.subtablefiltered[string[tbl];filter;""]]]]]]
     };

\d .

// the subdetails function adapted to also retrieve filters from the segmented tickerplant
segmentedsubdetails: {[tabs;instruments;segid] (!). flip 2 cut (
     `schemalist ; .stpps.subsegment\:[tabs;segid];                                 
     `logfilelist ; .stplg.replaylog[tabs];                                         
     `rowcounts ; ((),tabs)#.stplg `rowcount;	                                              
     `date ; (.eodtime `d);                                                         
     `logdir ; `$getenv`KDBTPLOG;                                                   
     `filters ; .stpps.filtermap[tabs;segid];
     `fullsubscriptions ; (flip .stpps.fullsubscriptions)[`tables];
     `ignoredtables ; (flip .stpps.ignoredtables)[`tables]
	)}
        
if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];


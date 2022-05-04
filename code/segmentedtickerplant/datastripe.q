//configload loads configurable .csv files into memory so relevant filters can be applied to data.

//.ds.segmentconfig/segmentfiltermap are variables which can take different csv files. These files can be chosen on in process.csv.
//error trap these .ds variables incase this file is loaded stand alone.

.ds.segmentconfig:@[value;`.ds.segmentconfig;`segmenting1.csv];

//if statement checks segmenting.csv and filtermap.csv exist. If not, process exited and message sent to error logs.
//configload transfoms segmenting.csv into table format so it can be accessed.
//checks csv files load correctly. If not, process exited and message sent to error logs.

configload:{
     scpath:first .proc.getconfigfile[string .ds.segmentconfig];
     {if[()~key hsym x;.lg.e[`init;"The following file can not be found: ",string x]]}scpath;
     @[{.stpps.segmentconfig:("SSI*S";enlist",")0: hsym x};scpath;{.lg.e[`init;"Failure in loading ",string y]}[;scpath]];
     .stpps.fullsubscriptions:exec table from .stpps.segmentconfig where subscription=`all;
     .stpps.ignoredtables:exec table from .stpps.segmentconfig where subscription=`ignore;
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };

\d .stpps

// Function to map the where clause from config table extracted by .stpps.segmentfilter function to tablename
// Allows use of ` as argument for tables
filtermap:{[tabs;id] if[tabs~`;tabs:.stpps.t]; ((),tabs)!.stpps.segmentfilter\:[(),tabs;id]};

// Find where clause from config tables
segmentfilter:{[tbl;segid]
       filter:first exec filter from .stpps.segmentconfig where segmentID=segid,table=tbl;
       $[0=count filter;filter:"";filter]
     };

// Subscribe to particular segment using segmentID based on .u.sub
// Uses .stpps.segmentconfig to handle subscriptions for each table
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
       [$[filter~"";             
                    [.lg.e[`sub;m:"Incorrect pairing of table ",string[tbl]," and segmentID ",string[segid]," not found in .stpps.segmentconfig"];
                    :(tbl;`err`msg!(`segmentid;m));]
                    ;
                    [.ps.subtablefiltered[string[tbl];filter;""]]]]]]]
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
     `fullsubscriptions ; .stpps.fullsubscriptions;
     `ignoredtables ; .stpps.ignoredtables
	)}
        
if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];


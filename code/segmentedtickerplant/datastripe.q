//Allows config file to be overwritten in process.csv
.ds.stripeconfig:$[not""~x:first .proc.params[`.ds.stripeconfig];x;"striping.json"];

// Loads the striping.json config file and logs any problems
configload:{[scpath]
      // Check for successful json read in and carry out jsonchecks
      .stpps.stripeconfig:@[{.j.k read1 x}; scpath;{.lg.e[`configload;"Failed to load in striping.json file: ",x]}];
      jsonchecks[]
     };

// Checks if each subscriptiondefault is set for each segment and errors if not defined
jsonchecks:{[]
     // check defaults are ignore or all
     defaults:value first each .stpps.stripeconfig[;`subscriptiondefault];
     errors:1+ where not defaults in\:("ignore";"all");
     if[0<count errors;.lg.o[`jsonchecks;"subscriptiondefault not defined as \"ignore\" or \"all\" for segment(s) "," " sv string[errors]]];
     // check for valid tables
     configtables: key(flip .stpps.stripeconfig[`segid]);
     stripedtables: .stpps.t inter configtables;
     wrongtables:(configtables except `subscriptiondefault) except stripedtables;
     if[0<count wrongtables;.lg.o[`jsonchecks;"Table(s) ",(" " sv string[wrongtables])," not recognised"]];
     //Enable datastriping if all checks pass
     .ds.datastripe:min (0=count errors; 0=count wrongtables);
     $[.ds.datastripe;
	[.lg.o[`jsonchecks;"config checks complete and datastriping is on"];
	// define segmentids from the striping config for use in pubsub.q 
        .ds.segmentlist:key .stpps.stripeconfig
        ];
	.lg.e[`jsonchecks;"Datastriping is not enabled due to failed config checks"]
     ];
     };

// Initialise config check
configcheck:{
     .lg.o[`configcheck;"initiate config check on ",.ds.stripeconfig," as .ds.torqv5mode is activated"];
     scpath:first .proc.getconfigfile[.ds.stripeconfig];
     // Check striping.json file exists and is not empty then run configload
     $[()~key hsym scpath;
       .lg.o[`configcheck;"Datastriping is not enabled as the following file can not be found: ", .ds.stripeconfig];
       $[()~read0 scpath;
         .lg.o[`configcheck;"Datastriping is not enabled as the following file is empty: ", .ds.stripeconfig];
         configload[scpath]]
      ];
     };

\d .stpps

//makes a dictionary of tables and their filters for segmentedsubdetails
filtermap:{[tabs;id] if[tabs~`;tabs:.stpps.t]; ((),tabs)!.stpps.segmentfilter\:[(),tabs;id]}

//grabs filters from the config files and for the "ignoretable" filter converts to "" to allow segmentedsudetails to run
segmentfilter:{[tbl;segid]
     id:`$string segid;
     filter:first (flip .stpps.stripeconfig[id])[tbl];
     $[filter~"ignoretable";filter:"";filter]
     };

//subscribe to a table using segmentID to determine filtering
subsegment:{[tbl;segid];
//casting segid to an symbol as json is restrictive
     id:`$string segid;
     if[not (id in (key .stpps.stripeconfig));
       .lg.e[`sub;m:"Segment ",string[segid]," is not defined in striping.json"];:()];
     ignoredtables:`$();
     //setting the default for non-configured tables
     default:.stpps.segmentfilter[`subscriptiondefault;segid];
     if[tbl~`;:.z.s[;segid] each .stpps.t];
     stripedtables:.stpps.t inter key flip .stpps.stripeconfig[id];
     //if the defualt is "all" tables not mentioned in striping.json will be subscribed unfiltered
     if[default~"all";suballtabs: .stpps.t except stripedtables;
       if[tbl in suballtabs;
          .lg.o[`sub;m:"Table ",string[tbl]," is to be subscribed unfiltered for segment ",string[segid],""]]];
     if[tbl in stripedtables;
       .lg.o[`sub;"Table ",string[tbl]," is to be subscribed filtered for segment ",string[segid],""]];
     //if default is ignore creates a list to of tables to ignore
     if[default~"ignore"; ignoredtables: .stpps.t except stripedtables];
     filter:.stpps.segmentfilter[tbl;segid];
     //for case when filter is "ignoretable" adds that table to ignoredtables list
     if[(first (flip .stpps.stripeconfig[id])[tbl])~"ignoretable";ignoredtables:ignoredtables,tbl];
     if[tbl in ignoredtables;
      .lg.o[`sub;m:"Table ",string[tbl]," is to be ignored for segment ",string[segid],""];
      :()];
      
     //if a filter has been provided use subtablefiltered, if not use subtable for all syms
     $[count filter;.ps.subtablefiltered[string[tbl];filter;""];.ps.subtable[string[tbl];""]]
     };

\d .

// the subdetails function adapted to also retrieve filters from the segmented tickerplant
segmentedsubdetails: {[tabs;instruments;segid] (!). flip 2 cut (
     `schemalist ; .stpps.subsegment\:[tabs;segid];                                 
     `logfilelist ; .stplg.replaylog[tabs];                                         
     `rowcounts ; ((),tabs)#.stplg `rowcount;	                                              
     `date ; (.eodtime `d);                                                         
     `logdir ; `$getenv`KDBTPLOG;
     `filters ; .stpps.filtermap[tabs;segid]
	)}

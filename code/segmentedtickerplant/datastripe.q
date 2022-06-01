//Allows config file to be overwritten in process.csv
.ds.stripeconfig:@[value;`.ds.stripeconfig;`striping.json];

//Loads the striping.json config file checks if each subscriptiondefault is set for each segment and errors if not defined
configload:{
     scpath:first .proc.getconfigfile[string .ds.stripeconfig];
     if[()~key hsym scpath;.lg.e[`init;"The following file can not be found: ",string scpath]];
     .stpps.stripeconfig:.j.k read1 scpath;
     defaults:{first (flip .stpps.stripeconfig[x])[`subscriptiondefault]}each key .stpps.stripeconfig;
     errors:1+ where {[x] not ("ignore"~x) or ("all"~x)}each defaults;
     {if[0<count x;.lg.e[`sub;m:"subscriptiondefault not defined as \"ignore\" or \"all\" for segment ",string[x]," "]]}each errors;
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
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
     if[not tbl in .stpps.t;
          .lg.e[`sub;m:"Table ",string[tbl]," not in list of stp pub/sub tables"];
          :();
     ];
     filter:segmentfilter[tbl;segid];
     if[tbl in .stpps.ignoredtables;:.stpps.suball[tbl]];
     if[filter~"";
          .lg.e[`sub;m:"Incorrect pairing of table ",string[tbl]," and segmentID ",string[segid]," not found in .stpps.segmentconfig"];
          :();];
     .ps.subtablefiltered[string[tbl];filter;""]
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

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

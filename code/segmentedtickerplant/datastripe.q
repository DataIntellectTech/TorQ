.ds.stripeconfig:@[value;`.ds.stripeconfig;`striping.json];


configload:{
     scpath:first .proc.getconfigfile[string .ds.stripeconfig];
     {if[()~key hsym x;.lg.e[`init;"The following file can not be found: ",string scpath]]};
     .stpps.stripeconfig:.j.k raze read0 scpath;
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };


\d .stpps

filtermap:{[tabs;id] if[tabs~`;tabs:.stpps.t]; ((),tabs)!.stpps.segmentfilter\:[(),tabs;id]}

segmentfilter:{[tbl;segid]
     id:`$string segid;
     first (flip .stpps.stripeconfig[id])[tbl]
     };

subsegment:{[tbl;segid];
     //casting segid to an symbol as json is restrictive
     id:`$string segid;
     //setting the default for non-configured tables
     default:first (flip .stpps.stripeconfig[id])[`subscriptiondefault];
     if[tbl~`;:.z.s[;segid] each .stpps.t];
     stripedtables:inter [key flip .stpps.stripeconfig[id];.stpps.t];
     if[default~"all";suballtabs: except[.stpps.t;stripedtables]];
     if[default~"ignore"; ignoredtables: except[.stpps.t;stripedtables]];
     filter:first (flip .stpps.stripeconfig[id])[tbl];
     if[filter~"ignore this table";ignoredtables:tbl]
     if[tbl in ignoredtables; :()];
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

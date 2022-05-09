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

substripe:{[tbl;segid];
     //casting segid to an symbol as json is restrictive
     segid:`$string segid;
     //setting the default non-configured table
     default:first (flip .stpps.stripeconfig[segid])[`subscriptiondefault];
     if[default~"ignore";.stpps.substripeignore[tbl;segid]];
     if[default~"all";.stpps.substripeall[tbl;segid]];
//     if[default~"all except list";.stpps.substripeignorelisted[tbl;segid]];
     };

substripeignore:{[tbl;segid]
     if[tbl~`;:.z.s[;segid] each .stpps.t];
     stripedtables:inter [key flip .stpps.stripeconfig[segid];.stpps.t];
     filter:first (flip .stpps.stripeconfig[segid])[tbl];
     if[tbl in stripedtables;.ps.subtablefiltered[string[tbl];filter;""]]
     };

substripeall:{[tbl;segid]
     if[tbl~`;:.z.s[;segid] each .stpps.t];
     stripedtables:inter [key flip .stpps.stripeconfig[segid];.stpps.t];
     filter:first (flip .stpps.stripeconfig[segid])[tbl];
     ignoredtables:`$();
     if[filter~"ignore this table";stripedtables:stripedtables where stripedtables<>tbl;ignoredtables:ignoredtables,tbl];
     if[tbl in stripedtables;.ps.subtablefiltered[string[tbl];filter;""]];
     if[&[not(tbl in stripedtables);not(tbl in ignoredtables)];.stpps.suball[tbl]]
     };

\d .

// the subdetails function adapted to also retrieve filters from the segmented tickerplant
segmentedsubdetails: {[tabs;instruments;segid] (!). flip 2 cut (
     `schemalist ; .stpps.substripe\:[tabs;segid];                                 
     `logfilelist ; .stplg.replaylog[tabs];                                         
     `rowcounts ; ((),tabs)#.stplg `rowcount;	                                              
     `date ; (.eodtime `d);                                                         
     `logdir ; `$getenv`KDBTPLOG                                                   
	)}

if[.ds.datastripe;.proc.addinitlist[(`initdatastripe;`)]];

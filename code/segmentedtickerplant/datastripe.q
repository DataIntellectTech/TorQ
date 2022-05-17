//Allows config file to be overwritten in process.csv

.ds.stripeconfig:@[value;`.ds.stripeconfig;`striping.json];

//Loads the striping.json config file checks if each subscriptiondefault is set for each segment and errors if not defined

configload:{
     scpath:first .proc.getconfigfile[string .ds.stripeconfig];
     {if[()~key hsym x;.lg.e[`init;"The following file can not be found: ",string scpath]]};
     .stpps.stripeconfig:.j.k raze read0 scpath;
     defaults:{first (flip .stpps.stripeconfig[x])[`subscriptiondefault]}each key .stpps.stripeconfig;
     errors:1+ where {[x] not ("ignore"~x) or ("all"~x)}each defaults;
     {if[0<count errors;.lg.e[`sub;m:"subscriptiondefault not defined for segment/segments ",string[x]," "]]}each errors;
     };

initdatastripe:{
     .lg.o[`init;"init datastriping"];
     configload[];
     };


\d .stpps

//makes a dictionary of tables and there filters for segmentedsubdetails

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
     stripedtables:inter [key flip .stpps.stripeconfig[id];.stpps.t];
//if the defualt is "all" tables not mentioned in striping.json will be subscribed unfiltered
     if[default~"all";suballtabs: except[.stpps.t;stripedtables];
     .lg.o[`sub;m:"Table ",string[tbl]," is to be subscribed unfiltered for segment ",string[segid],""]];
//if default is ignore creates a list to of tables to ignore
     if[default~"ignore"; ignoredtables: except[.stpps.t;stripedtables]];
     filter:.stpps.segmentfilter[tbl;segid];
//for case when filter is "ignoretable" adds that table to ignoredtables list
     if[(first (flip .stpps.stripeconfig[id])[tbl])~"ignoretable";ignoredtables:ignoredtables,tbl];
     if[tbl in ignoredtables;
      .lg.o[`sub;m:"Table ",string[tbl]," is to be ignored for segment ",string[segid],""];
 :()];
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

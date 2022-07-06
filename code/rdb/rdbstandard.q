\d .proc
/- Get the relevant RDB attributes
getattributes:{
    timecolumns:1!except[(::),gettimecolumns each tables[`.];(::)];
    attrtable:`date`tables`procname!
	({[timecolumns]
	  d:exec(min;max)@\:distinct`date$first each raze value each timecolumns from timecolumns;
	  first[d]+til 1+last deltas d}[timecolumns];
	tables[];
	.proc.procname);
    if[.ds.datastripe;
	filtermap:flip @[.j.k read1 hsym`$getenv[`KDBAPPCONFIG],"/striping.json";`$string first .ds.segmentid];
	filtermap:([]tablename:key filtermap)!([]wc:value filtermap);
	/- Match tables (and their timewindows) against the whereclause they've used to subscribe
	tablename:((key timecolumns)!select wc,timecolumns from update wc:{""}'[i],timecolumns from timecolumns)
		    lj
                      filtermap;
	dataaccess:enlist[`dataaccess]!enlist`segid`tablename!(first .ds.segmentid;tablename);
        attrtable,:dataaccess;
        ];
    attrtable}
/- Get names of all cols of type "p", "d", or "z" and the timeranges they span as a nested dictionary structure
gettimecolumns:{
    tcols:exec c from meta value x where t in "pdz";
    if[not count tcols;:(::)];
    (`tablename`timecolumns)!(x;
        /- functional exec to get the min value (defaults to `timestamp$.z.d for starttimestamp)
        ?[x;();();
	  tcols!(enlist,/:enlist each($;enlist`timestamp),/:enlist each((?),/:enlist each(in[;(0Wd;0Wp;0wz)]),/:mtcols),'`.z.d,'mtcols:enlist each min,/:tcols),\:0Wp])}
\d .rdb

/- Move a table from one namespace to another
/- this could be used in the end-of-day function to move the heartbeat and logmsg
/- tables out of the top level namespace before the save down, then move them 
/- back when done.
moveandclear:{[fromNS;toNS;tab] 
 if[tab in key fromNS;
  set[` sv (toNS;tab);0#fromNS tab];
  eval(!;enlist fromNS;();0b;enlist enlist tab)]}

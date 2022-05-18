\d .proc
/- Get the relevant RDB attributes
getattributes:{
    timecolumns:1!gettimecolumns each tables[`.];
    attrtable:`date`tables`procname!(.rdb.rdbpartition[];tables[];.proc.procname);
    if[.ds.datastripe;
        /- get segmentfilter from segmenting.csv and filtermap.csv
        /- assumes striping by sym
        segmenting:("SIS";enlist",")0:hsym`$getenv[`KDBCONFIG],"/segmenting.csv";
        segment:select wcRef,table from segmenting where segmentID in .ds.segmentid;
        filtermap:1!("S*";enlist",")0:hsym`$getenv[`KDBCONFIG],"/filtermap.csv";
        wc:1!select tablename:table,wc:{ssr[x;"sym";""]}each filter from segment ij filtermap;
        wcandtcs:wc uj timecolumns;
        dataaccess:enlist[`dataaccess]!enlist`segid`tablename!(first .ds.segmentid;(exec tablename from wcandtcs)!value wcandtcs);
        attrtable,:dataaccess;
        ];
    attrtable}
/- Get names of all cols of type "p", "d", or "z" and the timeranges they span as a nested dictionary structure
gettimecolumns:{
    tcols:exec c from meta value x where t in"pdz";
    (`tablename`timecolumns)!(x;
        /functional select to get the min value (defaults to `timestamp$.z.d for starttimestamp)
        ?[x;();();tcols!(enlist,/:enlist each($;enlist`timestamp),/:enlist each((?),/:enlist each(=;0W),/:mtcols),'`.z.d,'mtcols:enlist each min,/:tcols),\:0Wp])}
\d .rdb

/- Move a table from one namespace to another
/- this could be used in the end-of-day function to move the heartbeat and logmsg
/- tables out of the top level namespace before the save down, then move them 
/- back when done.
moveandclear:{[fromNS;toNS;tab] 
 if[tab in key fromNS;
  set[` sv (toNS;tab);0#fromNS tab];
  eval(!;enlist fromNS;();0b;enlist enlist tab)]}

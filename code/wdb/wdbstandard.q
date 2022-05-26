\d .proc
/- Get the relevant WDB attributes
getattributes:{
    timecolumns:1!gettimecolumns each tables[`.];
    attrtable:`date`tables`procname!
	/-lambda execs all datebased columns from table supplied
        ({[timecolumns]
          d:exec(min;max)@\:distinct`date$first each raze value each timecolumns from timecolumns;
          first[d]+til 1+last deltas d}[timecolumns];
	tables[];
	.proc.procname);
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

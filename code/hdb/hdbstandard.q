// reload function
reload:{
	.lg.o[`reload;"reloading HDB"];
	system"l ."}

// Get the relevant HDB attributes
\d .proc
getattributes:{
	timecolumns:except[(::),gettimecolumns each t:tables[`.];(::)];
	attrtable:`date`tables`procname!(
		@[value;`date;`date$()] union first[d]+til 1+last deltas d:exec(min;max)@\:distinct`date$last each raze value each timecolumns from timecolumns;
		tables[];
		.proc.procname);
    	/ select table using max date if date col exists
	/ get all cols that contains date (of type "pdz")
	attrtable[`dataaccess]:`segid`tablename!(first .ds.segmentid;t!select wc:{""}'[i],timecolumns from timecolumns);
    	attrtable}
// Get temporal cols and the time windows they contain
gettimecolumns:{
	tcols:exec c from meta t:$[`date in cols x;
	select from x where date=max date;
                value x] where t in "pdz";
	/ date cols
	dcols:exec c from meta t where t="d";
	if[not count tcols,dcols;:(::)];
        / functional exec to get the max value (defaults to -1+`timestamp$.z.d for endtimestamp)
	d:?[t;();();
		tcols!enlist,/:-0Wp,/:
			enlist each(?),/:(enlist each(=;-0W),/:mtcols),'(enlist(+;-1;($;ets;`.z.d))),/:enlist each($;ets:enlist`timestamp),/:mtcols:enlist each max,/:tcols];
	d[dcols]:`date$d dcols;
	enlist[`timecolumns]!enlist d}

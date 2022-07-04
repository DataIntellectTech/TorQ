// reload function
reload:{
	.lg.o[`reload;"reloading HDB"];
	system"l ."}

// Get the relevant HDB attributes
\d .proc
getattributes:{
	timecolumns:1!except[(::),gettimecolumns each t:tables[`.];(::)];
	attrtable:`date`tables`procname!(
		/ date reporting makes some assumptions
		@[value;`date;`date$()] union first[d]+til 1+last deltas d:exec(min;max)@\:distinct`date$last each raze value each timecolumns from timecolumns;
		tables[];
		.proc.procname);
	attrtable[`dataaccess]:`segid`tablename!(first .ds.segmentid;(key timecolumns)!select wc,timecolumns from update wc:{""}'[i],timecolumns from timecolumns);
    	attrtable}
// Get temporal cols and the time windows they contain
gettimecolumns:{
	tcols:exec c from meta t:$[`date in cols x;
    	/ select table using max date if date col exists
	select from x where date=max date;
                value x] where t in "pdz";
	if[not count tcols;:(::)];
        / functional exec to get the max value within each timebased column (defaults to -1+`timestamp$.z.d)
	d:?[t;();();
		tcols!enlist,/:-0Wp,/:
				enlist each(?),/:(enlist each(in[;(-0Wd;-0Wp;-0wz)]),/:mtcols),'(enlist(+;-1;($;ets;`.z.d))),/:enlist each($;ets:enlist`timestamp),/:mtcols:enlist each max,/:tcols];	
	/ date cols
	dcols:exec c from meta t where t="d";
	d[dcols]:`date$d dcols;
	`tablename`timecolumns!(x;d)}

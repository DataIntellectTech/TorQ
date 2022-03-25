// reload function
reload:{
	.lg.o[`reload;"reloading HDB"];
	system"l ."}

// Get the relevant HDB attributes
.proc.getattributes:{default:`date`tables`procname!(@[value;`date;`date$()];tables[];.proc.procname);
    / select table using max date if date col exists
	/ get all cols that contains date (of type "pdz")
	timecolumns:{tcols:exec c from meta t:$[`date in cols x;
		select from x where date=max date;
		value x]where t in"pdz";
		/ date cols
		dcols:exec c from meta t where t="d";
		/ functional select to get the max value (defaults to -1+`timestamp$.z.d for endtimestamp)
		dict:?[t;();();
			tcols!enlist,/:-0Wp,/:
				enlist each(?),/:(enlist each(=;-0W),/:mtcols),'(enlist(+;-1;($;ets;`.z.d))),/:enlist each($;ets:enlist`timestamp),/:mtcols:enlist each max,/:tcols];
		dict[dcols]:`date$dict dcols;
		enlist[`timecolumns]!enlist dict
		}each t:tables[`.];
	/ update date attribute for .gw.partdict and .gw.attributesrouting
	default[`date]:asc default[`date]union first[d]+til 1+last deltas d:exec(min;max)@\:distinct`date$raze[value each timecolumns][;1]from timecolumns;
	default,:enlist[`dataaccess]!enlist`segid`tablename!(.ds.segmentid 0;t!select instrumentfilter:{""}'[i],timecolumns from timecolumns);
    default}
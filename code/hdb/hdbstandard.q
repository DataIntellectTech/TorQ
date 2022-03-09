// reload function
reload:{
	.lg.o[`reload;"reloading HDB"];
	system"l ."}

// Get the relevant HDB attributes
.proc.getattributes:{default:`date`tables`procname!(@[value;`date;`date$()];tables[];.proc.procname);
	/ check if process attributes file exist
	if[count key fh:hsym`$getenv[`KDBCONFIG],"/processattributes.csv";
		processattributes:("SS*SNN***";enlist",")0:fh;
		if[.proc.procname in processattributes`procname;
			.hdb.dts:(min;max)@\:default`date;
			dataaccess:exec enlist[`tablename]!enlist tablename!
				{[tbl;inf;ptc;sts;ets;otc;sto;eto]
					/ primarytimecolumn defaults to `time if empty
					ptc:$[`~ptc;`time;ptc];
					/ starttime defaults to 0D00:00:00.000000000 if empty
					sts:$[0N=sts;0D00:00:00.000000000;sts];
					/ endtime defaults to 0D23:59:59.999999999 if empty
					ets:$[0N=ets;0D23:59:59.999999999;ets];
					/ timestamp dict
					td:enlist[ptc]!enlist .hdb.dts+(sts;ets);
					/ check if any empty othertimecolumns,starttimeoffsets,endtimeoffsets
					if[not any""~/:tl:(otc;sto;eto);
						ls:" "vs/:tl;
						/ check if same number of items in the columns
						$[1=count distinct count each ls;
							/ append othertimecolumns timestamps
							td,:(`$ls 0)!flip td[ptc]+'"N"$ls 1 2;
							'`$"Ensure that parameters `othertimecolumns`starttimeoffsets`endtimeoffsets has the same number of items"]
						];
					`instrumentsfilter`timecolumns!(inf;td)
					}'[tablename;instrumentsfilter;primarytimecolumn;starttime;endtime;othertimecolumns;starttimeoffsets;endtimeoffsets]
					from processattributes where procname=.proc.procname;
			/ nested dict structure of
			/ (`date`tables`procname`dataaccess)!(date;tables;procname;`tablename!(tablename!(`instrumentfilters`timecolumns!(instrumentfilters;timecolumns))))
			default,:enlist[`dataaccess]!enlist dataaccess;
			/ update date attribute for .gw.partdict and .gw.attributesrouting
			default[`date]:default[`date]union first[d]+til 1+last deltas d:(min;max)@\:distinct(raze/)`date$value each value(dataaccess`tablename)[;`timecolumns];
			];
		];
    default}
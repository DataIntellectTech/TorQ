// reload function
reload:{
	.[`.hdb.reloadcalls;();+;1];
	.lg.o[`reload;string[.hdb.reloadcalls]," out of ",string[.hdb.expectedreloadcalls]," calls received"];
	if[.hdb.reloadcalls<.hdb.expectedreloadcalls;:(::)];
	.lg.o[`reload;"reloading HDB"];
	system"l .";.[`.hdb.reloadcalls;();:;0];}

// Get the relevant HDB attributes
.proc.getattributes:{`date`tables!(@[value;`date;`date$()];tables[])}

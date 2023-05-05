// reload function
reload:{
	
	if[.z.w in key .hdb.reloadcalls;
		.hdb.reloadcalls[.z.w]:1b;
		.lg.o[`reload;"reload call received from handle ", string[.z.w], "; reload calls pending from handles ", ", "sv string where not .hdb.reloadcalls];
		if[not all .hdb.reloadcalls;:(::)]];
	.lg.o[`reload;"reloading HDB"];
	@[`.hdb.reloadcalls;key .hdb.reloadcalls;:;0b];
	system"l .";.[`.hdb.reloadcalls;();:;0];}

// Get the relevant HDB attributes
.proc.getattributes:{`date`tables!(@[value;`date;`date$()];tables[])}

\d .hdb

// dictionary of handles to reload
reloadcalls:()!();

// function to add handle to reloadcalls dictionary
po:{[h] if[.z.u in `wdb`rdb;reloadcalls[h]:0b]};
.z.po:{[f;x] @[f;x;()];.hdb.po x} @[value;`.z.po;{{}}];

// function to remove handle from reloadcalls dictionary
pc:{[h] reloadcalls _: h; if[all value .hdb.reloadcalls;reload[]]};
.z.pc:{[f;x] @[f;x;()];.hdb.pc x} @[value;`.z.pc;{{}}];

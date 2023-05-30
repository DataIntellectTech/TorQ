// reload function
reload:{
	.lg.o[`reload;"reloading QUERYHDB"];
	system"l ."}

// Get the relevant QUERYHDB attributes
.proc.getattributes:{`date`tables!(@[value;`date;`date$()];tables[])}

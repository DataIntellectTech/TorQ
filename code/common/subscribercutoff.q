//This script will cut off any slow subscibers if they exceed a memory limit

\d .subcut
cutenabled:@[value;`cutenabled;0b]			//flag for enabling subscriber cutoff. true means slow subscribers will be cut off
maxsize:@[value;`maxsize;100000]			//a global value for the max queue size of a subscriber
procsize:@[value;`procsize;(enlist `)!(enlist 0Nj)]	//a dictionary of process type and that processes queue size. This value will take precedence over maxsize
checkfreq:@[value;`checkfreq;0D00:01]			//the frequency for running the queue size check on subscribers


checksubs:{

	{[handle]
	//Get process type for input handle from .clients.clients
	proctype:first exec u from .clients.clients where w=handle;
	
	//if handle size is greater than maxsize or specified size in procsize, close the handle, call .z.pc and log the handle being cut.
	{[handle;proctype]if[(sum .z.W[handle]) >  (maxsize^procsize[proctype]);(hclose handle;.z.pc handle;.lg.o[`subscribercutoff;"Cutting off subscriber on handle ",string handle])]}[handle;proctype]} each key .z.W
	
	}

//if cut is enabled and timer code has been loaded, start timer for subscriber cut-off. Else output error.
if[cutenabled;
	$[@[value;`.timer.enabled;0b];
        	[.lg.o[`subscribercutoff;"adding timer function to periodically check subscriber queue sizes starting at ",string `timestamp$(.proc.cd[]+1)+00:00];
        	.timer.rep[.proc.cp[];0Wp;checkfreq;(`.subcut.checksubs`);0h;"run subscribercutoff";1b]];
		.lg.e[`subscribercutoff;".subcut.cutenabled is set to true, but timer functionality is not loaded - cannot cut-off slow subscribers"]]];

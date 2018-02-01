//This script will cut off any slow subscibers if they exceed a memory limit

\d .subcut
enabled:@[value;`enabled;0b]				//flag for enabling subscriber cutoff. true means slow subscribers will be cut off. Default is 0b
maxsize:@[value;`maxsize;100000000]			//a global value for the max byte size of a subscriber. Default is 100000000
breachlimit:@[value;`breachlimit;3]			//the number of times a handle can exceed the size limit check in a row before it is closed. Default is 3
checkfreq:@[value;`checkfreq;0D00:01]			//the frequency for running the queue size check on subscribers. Default is 0D00:01



state:()!()		                                //a dictionary to track how many times a handle breachs the size limit. Should be set to ()!()

checksubs:{
	//maintain a state of how many times a handle has breached the size limit
	.subcut.state:current[key .subcut.state]*.subcut.state+:current:(sum each .z.W)>maxsize;

	//if a handle exceeds the breachlimit, close the handle, call .z.pc and log the handle being closed.
	{[handle].lg.o[`subscribercutoff;"Cutting off subscriber on handle ",(string handle)," due to large buffer size at ",(string sum .z.W handle)," bytes"];
         @[hclose;handle;{.lg.e[`subscribercutoff;"Failed to close handle ",string handle]}]; .z.pc handle} each where .subcut.state >= breachlimit;
	}

//if cut is enabled and timer code has been loaded, start timer for subscriber cut-off, else output error.
if[enabled;
	$[@[value;`.timer.enabled;0b];
        	[.lg.o[`subscribercutoff;"adding timer function to periodically check subscriber queue sizes"];
        	.timer.rep[.proc.cp[];0Wp;checkfreq;(`.subcut.checksubs`);0h;"run subscribercutoff";1b]];
		.lg.e[`subscribercutoff;".subcut.enabled is set to true, but timer functionality is not loaded - cannot cut-off slow subscribers"]]];

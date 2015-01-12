// Functionality to extend the timer

\d .timer

enabled:@[value;`enabled;1b]				// whether the timer is enabled
debug:@[value;`debug;0b]				// print when the timer runs any function
logcall:@[value;`logcall;1b]				// log each timer call by passing it through the 0 handle
nextscheduledefault:@[value;`nextscheduledefault;2h]	// the default way to schedule the next timer
							// Assume there is a function f which should run at time T0, actually runs at time T1, and finishes at time T2
                                        		// if mode 0, nextrun is scheduled for T0+period
                                        		// if mode 1, nextrun is scheduled for T1+period
                                        		// if mode 2, nextrun is scheduled for T2+period	
id:0
getID:{:id+::1}

// Store a table of timer values 
timer:([id:`int$()]			// the of the timer
 timerchange:`timestamp$();		// when the function was added to the timer
 periodstart:`timestamp$();		// the first time to fire the timer 
 periodend:`timestamp$(); 		// the the last time to fire the timer	
 period:`timespan$();			// how often the timer is run
 funcparam:();				// the function and parameters to run
 lastrun:`timestamp$();			// the last run time
 nextrun:`timestamp$();			// the next scheduled run time
 active:`boolean$();			// whether the timer is active
 nextschedule:`short$();		// determines how the next schedule time should be calculated
 description:());			// a free text description

// utility function to check funcparam comes in the correct format
check:{[fp;dupcheck]
	if[dupcheck;
		if[count select from timer where fp~/:funcparam;
                        '"duplicate timer already exists for function ",(-3!fp),". Use .timer.rep or .timer.one with dupcheck set to false to force the value"]];
	$[0=count fp; '"funcparam must not be an empty list";
	  10h=type fp; '"funcparam must not be string.  Use (value;\"stringvalue\") instead";
	  fp]}

// add a repeatingtimer
rep:{[start;end;period;funcparam;nextsch;descrip;dupcheck] 
	if[not nextsch in `short$til 3; '"nextsch mode can only be one of ",-3!`short$til 3];
	`.timer.timer upsert (getID[];.z.p;start:.z.p^start;0Wp^end;period;check[funcparam;dupcheck];0Np;start+period;1b;nextsch;descrip);}

// add a one off timer
one:{[runtime;funcparam;descrip;dupcheck] 
        `.timer.timer upsert (getID[];.z.p;.z.p;0Np;0Nn;check[funcparam;dupcheck];0Np;runtime;1b;0h;descrip);}

// projection to add a default repeating timer.  Scheduling mode 2 is the safest - least likely to back up
repeat:rep[;;;;nextscheduledefault;;1b]
once:one[;;;1b]

// Remove a row from the timer 
remove:{[timerid] delete from `.timer.timer where id=timerid}
removefunc:{[fp] delete from `.timer.timer where fp~/:funcparam}

// run a timer function and reschedule if required
run:{
	// Pull out the rows to fire
	// Assume we only use period start/end when creating the next run time
	// sort asc by lastrun so the timers which are due and were fired longest ago are given priority
	torun:`lastrun xasc 0!select from timer where active,nextrun<x;	
	runandreschedule each torun}

// run a timer function and reschedule it if required
runandreschedule:{
	// if debug mode, print out what we are doing 	
	if[debug; .lg.o[`timer;"running timer ID ",(string x`id),". Function is ",-3!x`funcparam]];
	start:.z.p;
	@[$[logcall;0;value];x`funcparam;{update active:0b from `.timer.timer where id=x`id; .lg.e[`timer;"timer ID ",(string x`id)," failed with error ",y,".  The function will not be rescheduled"]}[x]];
	// work out the next run time
	n:x[`period]+(x[`nextrun];start;.z.p) x`nextschedule;
	// check if the next run time falls within the sceduled period
	// either up the nextrun info, or switch off the timer
	$[n within x`periodstart`periodend;
		update lastrun:start,nextrun:n from `.timer.timer where id=x`id;
		[if[debug;.lg.o[`timer;"setting timer ID ",(string x`id)," to inactive as next schedule time is outside of scheduled period"]];
		 update lastrun:start,active:0b from `.timer.timer where id=x`id]];
	}

// Set .z.ts
if[.timer.enabled;
 $[@[{value x;1b};`.z.ts;0b];
   .z.ts:{.timer.run[y]; x@y}[.z.ts];
   .z.ts:{.timer.run[x]}];

 // Set the timer to 200ms if not set already
 if[not system"t"; system"t 200"]];
	
\
f:{0N!`firing;x+1}
f1:{0N!`firing;system"sleep ",string x}
repeat[.z.p;.z.p+0D00:01;0D00:00:15;(f1;2);"test timer"]
rep[.z.p;.z.p+0D00:01;0D00:00:15;(f1;3);0h;"test timer";1b]
rep[.z.p;.z.p+0D00:01;0D00:00:15;(f1;4);1h;"test timer";1b]

once[.z.p+0D00:00:10;(`.timer.f;2);"test once"]  
.z.ts:run
\t 500

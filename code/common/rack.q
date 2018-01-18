// define a utils namespace

intervals:{[args]
   if[args[`intervals.start]>args[`intervals.end];'`$"start time should be less than end time"];
   if[not `intervals.round in key args;args:args,(enlist `base)!enlist 1b]; //if round isn't provided create  a default 1b boolean
   if[not all `intervals.start`intervals.end`intervals.interval in key args; '`$"start, end, and interval must be specified in function call"]; // if start end or interval aren't provide

   $[args[`intervals.round];
	// if round is specified we subtract the end value from start value, then create a list from 0 to that value using til
	// by multipying by the interval and andding the start time again we creat a list of intervals between the start and end time
	// if we divide this list by the interval value again we will get a ist of floats, when we convert this back to a `long
	// it will round up (or down) to the mulitple of the interval. Convert this list to a list of type `start to finish
	// due to the nature of this there might be one final value higher than the end point so do a check and delete it if it is.
        [x: (neg type args[`intervals.start])$args[`intervals.interval]*`long$(args[`intervals.start] + args[`intervals.interval]*til 1+ `int$(args[`intervals.end]-args[`intervals.start])%args[`intervals.interval])%args[`intervals.interval];$[args[`intervals.end] < last x;x:-1 _x;x]];
	// this is the same as the above but we don't divide by interval and convert to long again so rounding doesn't take place
	[x: (args[`intervals.start] + args[`intervals.interval]*til 1+`long$(args[`intervals.end]-args[`intervals.start])%args[`intervals.interval]);$[args[`intervals.end] < last x;x:-1 _x;x]]]
    };

rack:{[args]
	// we set a variable 'timeseries' to a null list, and if a base is not provided we do the same for that variable.
	// advantage is that if a null list is crossed with a table it returns an unaltered table, allowing multiple if/elses to be eliminated
      	timeseries:enlist ();
	$[.Q.qt args[`table]; args[`table]:0!args[`table];
                '`$"valid table or keyed table must be provided in arguments"];
         // if base is given in the function call make sure that it's a table or assign it a null value if it's not called
         $[`base in key args;if[not .Q.qt args[`base];'`$"if base is specified it must be as a table"];
                args:args,(enlist`base)!enlist 1#()];

	// if arguments for a timeseries are provided we give them to the intervals functions to create an interval column to rack against
	if[`timeseries in key args;
		timeseries:([]interval:intervals[args[`timeseries]])];
	// if full expansion isn't prvided, default it to 0b
	if[not `fullexpansion  in key args;args:args,(enlist `fullexpansion)!enlist 0b]; 
	
	//This is where actual racking is done
	$[args[`fullexpansion];
		/ If fullexpansion is true we cross each column of the table with the others. 
		/ flip the entries of the table, and cross over them, and then insert the distinct results into an empty copy of the original table 
		racktable:args[`base] cross (((0#args[`keycols]#args[`table]) upsert distinct (cross/)value flip args[`keycols]#args[`table]) cross timeseries);
		/if full expansion isn't true, just cross rhe required key columns first with a base then with the timeseries
		racktable:args[`base] cross ((args[`keycols]#args[`table]) cross timeseries)] 

	}


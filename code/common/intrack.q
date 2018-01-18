checkargs:{[fname;args;klist]
	if[not 99h=type args;'`$"Supplied arguments must be in the form of a dictionary"];
	if[not all klist in key args;'`$"arguments provided do not match expected inputs of ",string klist];
	if[fname in `rack`ffills`pivot;
          	$[not .Q.qt args[`table];'`$"The datatype assigned to the argument:`table should be given as a table";
		  not all -11h  = type each args[`keycols];'`$"Keycols must be supplied as symbols";
		  not all args[`keycols] in cols args[`table];'`$"Sprecified keycols do not exist in table";()]];
	    	
		};

		
intervals:{[args]
	// Call general checkargs function
	checkargs[`intervals;args;`start`end`interval];
	// Error checks specific to intervals
	if[args[`start]>args[`end];'`$"start time should be less than end time"];
	if[not (type args[`start`end]) in `short$5,6,7,(12+til 8) except 15; '`$"start and end must be of same type and must be one of timestamp, month, date, timespan, minute, second, time"];
	if[(args[`end] - args[`start]) > args[`interval];'`$"Difference between start and end points smaller than interval specified, please use a smaller interval"]
	// Check optional arguments and assign defaults where appropriate
	$[`round in key args;
		if[not -1 = type args[`round];'`$"round should be specified as a boolean value"];
		args:args,(enlist `round)!enlist 1b]]
	$[args[`round];
		[x:(neg type args[`start])$(`long$args[`interval])*`long$(args[`start] + args[`interval]*til 1+ `int$(args[`end]-args[`start])%args[`interval])%args[`interval];
		$[args[`end] < last x;x:-1 _x;x]];
	// this is the same as the above but we don't divide by interval and convert to long again so rounding doesn't take place
		[x: (args[`start] + args[`interval]*til 1+`long$(args[`end]-args[`start])%args[`interval]);
		$[args[`end] < last x;x:-1 _x;x]]]
    };

rack:{[args]
	// Call general check args function
	checkargs[`rack;args;`table`keycols];
	// Check Optional arguments and assign defaults where appropriate
	// Set a variable 'timeseries' to a null list
      	timeseries:enlist ();
	$[.Q.qt args[`table]; args[`table]:0!args[`table]];
         // if base is given in the function call make sure that it's a table or else assign it to a null list
        $[`base in key args;
	  if[not .Q.qt args[`base];'`$"if base is specified it must be as a table"];
             args:args,(enlist`base)!enlist 1#()];
	// if arguments for a timeseries are provided creat intervals column
	if[`timeseries in key args;checkargs[`timeseries;args[`timeseries];`intervals.start`intervals.end`intervals.interval];
		args[`timeseries]:("S"$ssr[;"intervals.";""] each (string key args[`timeseries]))!value args[`timeseries];
		timeseries:([]interval:intervals[args[`timeseries]])];
	// if full expansion isn't provided, default it to 0b
	$[`fullexpansion  in key args;if[not -1 = type args[`fullexpansion];'`$"fullexpansion must be provided as a boolean value"];
		args:args,(enlist `fullexpansion)!enlist 0b]; 
	
	//This is where actual racking is done
	$[args[`fullexpansion];
		/ If fullexpansion is true we cross each column of the table with the others. 
		racktable:args[`base] cross ((cross/){distinct each (enlist each cols[x])#\:x}args[`keycols]#args[`table]) cross timeseries;
		/if full expansion isn't true, just cross rhe required key columns first with a base then with the timeseries
		racktable:args[`base] cross ((args[`keycols]#args[`table]) cross timeseries)] }


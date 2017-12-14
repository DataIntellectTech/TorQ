// define a namespace
checkargs:{[fname;args]
        if[not 99h=type args;'`$"supplied arguments must be in the form of a dictionary"];
        if[fname in `rack`ffills`pivot;
                if[not .Q.qt args[`table];'`$"the datatype assigned to the table argument is not a table"];
                if[not all args[`keycols] in cols  args[`table];'`$"Sprecified keycols do not exist in table"];




intervals:{[args]
   if[args[`start]>args[`end];'`$"start time should be less than end time"];
   if[type args[`start] in (-1,-4,-8,-9,) ;'`$"DateTime should not be used as a parameter; underlying float value may yield unexpected results"];
   if[-9h = type args[`start]];'`$"Float value should not be used in function call, as may yield unexpected results"];
   //if round isn't provided create  a default 1b boolean
   if[not `round in key args;args:args,(enlist `base)!enlist 1b];
   if[not -1 = type args[`round];'`$"round should be specified as a boolean value"];
   // to be added in checkargs
   // if[not all `start`end`interval in key args; '`$"start, end, and interval must be specified in function call"];

   $[args[`round];
	// if round is specified we subtract the end value from start value, then create a list from 0 to that value using til
	// by multipying by the interval and andding the start time again we creat a list of intervals between the start and end time
	// if we divide this list by the interval value again we will get a ist of floats, when we convert this back to a `long
	// it will round up (or down) to the mulitple of the interval. Convert this list to a list of type `start to finish
	// due to the nature of this there might be one final value higher than the end point so do a check and delete it if it is.
        [x:(neg type args[`start])$args[`interval]*`long$(args[`start] + args[`interval]*til 1+ `int$(args[`end]-args[`start])%args[`interval])%args[`interval];
	$[args[`end] < last x;x:-1 _x;x]];
	// this is the same as the above but we don't divide by interval and convert to long again so rounding doesn't take place
	[x: (args[`start] + args[`interval]*til 1+`long$(args[`end]-args[`start])%args[`interval]);
	$[args[`end] < last x;x:-1 _x;x]]]
    };

rack:{[args]
	// we set a variable 'timeseries' to a null list
      	timeseries:enlist ();
	$[.Q.qt args[`table]; args[`table]:0!args[`table];
         // if base is given in the function call make sure that it's a table or assign it to a null list if it's not called
         $[`base in key args;if[not .Q.qt args[`base];'`$"if base is specified it must be as a table"];
                args:args,(enlist`base)!enlist 1#()];

	// if arguments for a timeseries are provided we give them to the intervals functions to create an interval column to rack against
	if[`timeseries in key args;
		args[`timeseries]:("S"$ssr[;"intervals.";""] each (string key args[`timeseries]))!value args[`timeseries];
		timeseries:([]interval:intervals[args[`timeseries]])];
	// if full expansion isn't prvided, default it to 0b
	if[not `fullexpansion  in key args;args:args,(enlist `fullexpansion)!enlist 0b]; 
	
	//This is where actual racking is done
	$[args[`fullexpansion];
		/ If fullexpansion is true we cross each column of the table with the others. 
		racktable:args[`base] cross ((cross/){distinct each (enlist each cols[x])#\:x}args[`keycols]#args[`table]) cross timeseries;
		/if full expansion isn't true, just cross rhe required key columns first with a base then with the timeseries
		racktable:args[`base] cross ((args[`keycols]#args[`table]) cross timeseries)] 

	}


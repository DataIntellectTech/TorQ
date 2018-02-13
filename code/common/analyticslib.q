\d .al
/ - General argument checking funciton

checkargs:{[args;k;t]
 	$[not 99h~type args;'`$"Input parameter must be a dictionary with keys:\n\t-",sv["\n\t-";string k];  / - check for dictionary
        / - check for keys
        not all key[args] in k;'`$"Dictionary keys are incorrect. Keys should be:\n\t-", sv["\n\t-";string k], "\nYou have input keys:\n\t-", sv["\n\t-";string key args];
        / - check for types
		/ any not in'[string .Q.ty'[args k];t]
        any not .Q.ty'[args k] in t;'`$("One or more of your inputs are of an invalid type.");
        `table in key args;
        / - check if columns are in table provided
        (if[any not args[`keycols] in cols args`table;'`$("The columns (", raze string args[`keycols],") you are attempting to use does not exist in the table provided.")]);
        :()]
    }


/ - Forward fill function 
ffill:{[args]
	 / - Checks type of each column and fills accordingly
    forwardfill:{
        $[0h=type x;
            x maxs (til count x)*(0<count each x);
            fills x]
    };
		/ - If the input is just a table
	if[.Q.qt args;
		/ - update fills col1,fills col2,fills col3... from table                            
        :(![args;();0b;cols[args]!(`forwardfill),/:cols args])];
		/ - Check which columns are being filled
	if[`~args[`keycols];args[`keycols]:cols args`table];
		/ - Call checkargs function  
	checkargs[args;(`table`by`keycols);(" sS")];	
    $[`~args`by;
	    / - Functional update to forward fill
		/ - Equivalent to:
		/ - update fills keycols1,fills keycol2,fills keycol3 from table
	    ![args`table;();0b;((),args`keycols)!(`forwardfill),/:((),args`keycols)];
    	/ - Funciontal update to forward fill by specific column(s)
		/ - Equivalent to:
		/ - update fills keycols1,fills keycols2,fills keycols3 by `sym from table
    	![args`table;();((),args`by)!((),args`by);((),args`keycols)!(`forwardfill),/:((),args`keycols)]
    ]

	};


/ - General pivot function
pivot:{[args]
	checkargs[args;`table`by`piv`var;(" sS")];
 	/ - if user has not specified f or g set to defaults
 	if[not all `f`g in key args;
    	args[`f]:{[v;P] `$"_" sv' string (v,()) cross P};
    	args[`g]:{[k;P;c] k,asc c}];
	/ - Call check function on input
	(args`var):(),args[`var];
	G:group flip (args[`by])!((args[`table]):0!.Q.v (args[`table]))(args`by),:();
	F:group flip (args[`piv])!(args[`table]) (args`piv),:();
	count[args`by]!(args`g)[args`by;P;C]xcols 0!key[G]!flip(C:(args`f)[args`var]P:flip value flip key F)!raze
	{[i;j;k;x;y]
	 	a:count[x]#x 0N;
	 	a[y]:x y;
		b:count[x]#0b;
		b[y]:1b;
		c:a i;
		c[k]:first'[a[j]@'where'[b j]];
		c}[I[;0];I J;J:where 1<>count'[I:value G]]/:\:[(args`table) (args`var);value F]
	
	};

/- intervals function
	
intervals:{[args]
    / Call general checkargs function
    checkargs[args;`start`end`interval`round;("MmuUjJhHNnVvDdPpB")];
    / Error checks specific to intervals
    if[args[`start]>args[`end];'`$"start time should be less than end time"];
    if[not (type args[`start`end]) in `short$5,6,7,(12+til 8) except 15; '`$"start and end must be of same type and must be one of timestamp, month, date, timespan, minute, second, time"];
    if[(args[`end] - args[`start]) < args[`interval];'`$"Difference between start and end points smaller than interval specified, please use a smaller interval"]
    / Check optional arguments and assign defaults where appropriate
    $[`round in key args;
        if[not -1 = type args[`round];'`$"round should be specified as a boolean value"];
        args:args,(enlist `round)!enlist 1b];
    / need the `long on the multiplying interval because of timestamp issues
    $[args[`round];
       x:(neg type args[`start])$(`long$args[`interval])*`long$(args[`start] + args[`interval]*til 1+ `long$(args[`end]-args[`start])%args[`interval])%args[`interval];
    / this is the same as the above but we don't divide by interval and convert to long again so rounding doesn't take place
       x:args[`start] + args[`interval]*til 1+`long$(args[`end]-args[`start])%args[`interval]];
    $[args[`end] < last x;x:-1 _x;x] 
    };

/rack function
rack:{[args]
    / Call general check args function
    checkargs[args;`table`keycols`base`fullexpansion`timeseries`round;" sSB"]; 
    / Check Optional arguments and assign defaults where appropriate
    / Set a variable 'timeseries' to an empty list
        timeseries:enlist ();
    if[.Q.qt args[`table]; args[`table]:0!args[`table]];
        / if base is given in the function call make sure that it's a table or else assign it to a null list
        $[`base in key args;
        if[not .Q.qt args[`base];'`$"if base is specified it must be as a table"];
              args[`base]:enlist () ];
    / if arguments for a timeseries are provided create intervals column
    if[`timeseries in key args;
        timeseries:([]interval:intervals[args[`timeseries]])];
    / if full expansion isn't provided, default it to 0b
    $[`fullexpansion  in key args;if[not -1 = type args[`fullexpansion];'`$"fullexpansion must be provided as a boolean value"];
        args[`fullexpansion]:0b];
	if[1=count args[`keycols];
	   args[`keycols]:enlist args[`keycols]];
    / This is where actual racking is done
    $[args[`fullexpansion];
        / If fullexpansion is true we cross each column of the table with the others.
        racktable:args[`base] cross ((cross/){distinct each (enlist each cols[x])#\:x}args[`keycols]#args[`table]) cross timeseries;
        /if full expansion isn't true, just cross rhe required key columns first with a base then with the timeseries
        racktable:args[`base] cross ((args[`keycols]#args[`table]) cross timeseries)] }




\d .


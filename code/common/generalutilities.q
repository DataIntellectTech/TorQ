\d .gu

/ - Forward fill function with error checking on the inputs
ffill:{[args]
    
	/ - Generate dictionary for checkargs[]
	check:{[args]
		/ - Check if the input is a table		
    	$[.Q.qt args;:();
			/ - If not create the dictionary for checkargs[]
    		[dict:(`d`k)!(args;`table)
			/ - Check if `table argument is a table
    		if[not .Q.qt args`table;
				'`$"Table element of parameter dictionary is not a table or keyed table"]]
    	];		
		/ - Add to dictionary for checkargs depending on input
    	$[(`by in key args) & (`col in key args);dict[`t`e]:(`by`col;args[`by],args[`col]);
		`col in key args;dict[`t`e]:(`col;args`col);
		`by in key args;dict[`t`e]:(`by;args`by)
		];
		checkargs[dict];
    };
	/ - Call check function on input
	check[args]

	/ - Checks type of each column and fills accordingly
    forwardfill:{
        $[0h=type x;
            x maxs (til count x)*(0<count each x);
            fills x]
    };

 	/ - 
	$[.Q.qt args;
        ![args;();0b;(cols args)!(`forwardfill),/:cols args];
        [
        / - Assign columns to be forward filled
        $[`col in key args;col:(),args`col;col:cols args`table];
        $[not `by in key args;
            / - Functional update to forward fill
            ![args`table;();0b;(col)!(`forwardfill),/:col];
            / - Funciontal update to forward fill by keyed columns
            ![args`table;();((),args`by)!((),args`by);(col)!(`forwardfill),/:col]]
        ]
    ]

	}

/ - General pivot function
pivot:{[args]
 	/ - if user has not specified f or g set to defaults
 	if[not all `f`g in key args;
    	args[`f]:{[v;P] `$"_" sv' string (v,()) cross P};
    	args[`g]:{[k;P;c] k,asc c}];
	
 	check:{[args]
		dict:(`d`k`t`e)!(args;`table`by`piv`var;`by`piv`var;(args[`by],args[`piv],args[`var]));
		checkargs[dict]
    	if[not .Q.qt args`table;
			'`$"Table element of input is not a table or keyed table"];
    };
	/ - Call check function on input
	check[args];
	(args`var):(),args`var;
	G:group flip (args`by)!((args[`table]):0!.Q.v (args[`table]))(args`by),:();
	F:group flip (args`piv)!(args`table) (args`piv),:();
	count[args`by]!(args`g)[args`by;P;C]xcols 0!key[G]!flip(C:(args`f)[args`var]P:flip value flip key F)!raze
	{[i;j;k;x;y]
	 	a:count[x]#x 0N;
	 	a[y]:x y;
		b:count[x]#0b;
		b[y]:1b;
		c:a i;
		c[k]:first'[a[j]@'where'[b j]];
		c}[I[;0];I J;J:where 1<>count'[I:value G]]/:\:[(args`table) (args`var);value F]
	
	}
 
/ - general argument checking function
checkargs:{[dict]
	/ - dictionary check
	if[not 99h~type dict`d;'`$"Input parameter must be of type 99h"];
	/ - key check
	if[`k in key dict;
		if[not all dict[`k] in key dict[`d];'`$("Dictionary keys are incorrect")]
	];
	/ - type check
	if[`t in key dict;
	{[x;y] if[not any ("s";"S") in .Q.ty x y;'`$((string y)," element of parameter dictionary is not of type -11h or 11h")]} [dict`d;] each dict`t
	];
 	/ - existence check 
	if[`e in key dict;
	{[x;y] if[not all y in cols x;'`$((string y)," does not exist in the supplied table")]}[dict[`d] `table;]each dict`e
	];
	}

\d .


/ - Forward fill function, ffill
/ - takes as input a parameter dictionary of a table and the column you want to key by,
/ - i.e.
/ - update fill col1 by col2 from table becomes
/ - dict:(`table`keyedcols)!(table;col2)
/ - ffill[dict]


\d .f
/ - Forward fill function with error checking on the inputs
ffill:{[args]
    / - checks type of each column and fills accordingly
    forwardfill:{
    $[0h=type x;
    x maxs (til count x)*(0<count each x);
    fills x]
    };
    / - Check parameter dictionary for errors
    checkargs[args];
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



/ - Input parameter checklist
/ - 1,   If the input is just a table
/ - 1-1. If paramter dictionary is a dictionary
/ - 1-2. If the keys in the dictionary are correct
/ - 1-3. If first parameter is a table
/ - 2.   Is the user specifying keyed columns
/ - 2-1. If so are they the correct type
/ - 2-2. Also do they exist in the given table
/ - 3.   Is the user specifying the columns to fill
/ - 3-1. If so are they the correct type
/ - 3-2. Also do they exist in the given table

checkargs:{[args]
    $[
    .Q.qt args;:();
    not 99h~type args;'`$"Input parameter must be of type 99h";
    not all `table in key args; '`$"Dictionary must have at least key of `table";
    not .Q.qt args`table;'`$"Table element of parameter dictionary is not a table or keyed table";
    ];
    $[
    not `by in key args;:();
    not any ("s";"S") in .Q.ty args`by;'`$"By element of parameter dictionary is not of type -11h or 11h";
    not all (args`by) in cols args`table;'`$"By elements must exist in the supplied table"
    ];
    $[
    not `col in key args;:();
    not any ("s";"S") in .Q.ty args`col;'`$"Col element of parameter dictionary is not of type -11h or 11h";
    not all (args`col) in cols args`table;'`$"Col elements must exist in the supplied table"
    ];
    }


\d .

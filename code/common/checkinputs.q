\d .checkinputs

// checkinputs is the main function called when running a query - it checks:
//   (i) input format
//  (ii) whether any parameter pairs clash
// (iii) parameter specific checks
// The input dictionary accumulates some additional table information/inferred info
checkinputs:{[dict]
    dict:isdictionary dict;
    dict:checkdictionary dict;
    dict:checkinvalidcombinations dict;
    dict:checkrepeatparams dict;
    dict:checkeachparam[dict;1b];
    dict:checkeachparam[dict;0b];
    dict[`checksperformed]:1b;
    :dict;
  };

checkdictionary:{[dict]
    if[not checkkeytype dict;'`$"Input dictionary must have keys of type 11h"];
    if[not checkrequiredparams dict;'`$.checkinputs.formatstring["Required parameters missing:{}";.checkinputs.getrequiredparams[]except key dict]];
    if[not checkparamnames dict;'`$.checkinputs.formatstring["Invalid parameter present:{}";key[dict]except .checkinputs.getvalidparams[]]];
    :dict;
  };

isdictionary:{[dict]$[99h~type dict;:dict;'`$"Input must be a dictionary"]};
checkkeytype:{[dict]11h~type key dict};
checkrequiredparams:{[dict]all .checkinputs.getrequiredparams[]in key dict};
getrequiredparams:{[]exec parameter from .checkinputs.checkinputsconfig where required}
checkparamnames:{[dict]all key[dict]in .checkinputs.getvalidparams[]};
getvalidparams:{[]exec parameter from .checkinputs.checkinputsconfig};

checkinvalidcombinations:{[dict]
    parameters:key dict;
    xinvalidpairs:select parameter,invalidpairs:invalidpairs inter\:parameters from .checkinputs.checkinputsconfig where parameter in parameters;
    xinvalidpairs:select from xinvalidpairs where 0<>count'[invalidpairs];
    if[0=count xinvalidpairs;:dict];
    :checkeachpair[raze each flip xinvalidpairs];
  };

checkeachpair:{[invalidpair]'`$.checkinputs.formatstring["Parameter:{parameter} cannot be used in conjunction with parameter(s):{invalidpairs}";invalidpair]};

// function to check if any parameters are repeated
checkrepeatparams:{[dict]
    if[any repeats:1<count each group key dict;
        '`$.checkinputs.formatstring["{} parameter(s) used more than once";where repeats]];
    :dict;};

// loop thorugh input parameters to execute parameter specific checks
checkeachparam:{[dict;isrequired]
    config:select from .checkinputs.checkinputsconfig where parameter in key dict,required=isrequired;
    :checkparam/[dict;config];
  };

// extract parameter specific function from config to check the input
checkparam:{[dict;config]
    (first config[`checkfunction])[dict;first config`parameter]};

// check tablename parameter is of type symbol
checktable:{[dict;parameter]:checktype[-11h;dict;parameter];};

// check that endtime is of type symbol and that it is greater than or equal to starttime
checkendtime:{[dict;parameter]
    dict:checktimetype[dict;parameter];
    :checktimeorder dict};

// check that inputted value is of valid type: -12 -14 -15h
checktimetype:{[dict;parameter]:checktype[-12 -14 -15h;dict;parameter];};

// check timecolumn is of type symbol
// check starttime <= endtime
checktimecolumn:{[dict;parameter]:checktype[-11h;dict;parameter];};

// check starttime <= endtime
checktimeorder:{[dict]
    if[dict[`starttime] > dict`endtime;'`$"Starttime parameter must be <= endtime parameter"];
    :dict;};

// check instruments are of type symbol
checkinstruments:{[dict;parameter]
    :checktype[-11 11h;dict;parameter];};

// check columns are of type symbol
checkcolumns:{[dict;parameter]
    :checktype[-11 11h;dict;parameter];};

// check groupings are of type symbol
checkgrouping:{[dict;parameter]
    :checktype[-11 11h;dict;parameter];};

// check aggregations are of type dictionary, that the dictionary has symbol keys, that 
// the dictionary has symbol values
checkaggregations:{[dict;parameter]
    example:"`max`min`wavg!(`price;`size;`price`size)";
    dict:checktype[99h;dict;parameter];
    input:dict parameter;
    if[not 11h~abs type key input;
        '`$"Aggregations parameter key must be of type 11h - example: ",example];
    if[not all 11h~/:abs raze type''[get input];
        '`$"Aggregations parameter values must be of type symbol - example: ",example];
    :dict;
  };

// check that timebar parameter has three elements of respective types: numeric, symbol,
// symbol.
checktimebar:{[dict;parameter]
    input:dict parameter;
    if[not(3=count input)&0h~type input;
        '`$"Timebar parameter must be a list of length 3"];
    input:`size`bucket`timecol!input;
    if[not any -6 -7h~\:type input`size;
        '`$"First argument of timebar must be either -6h or -7h"];
    if[not -11h~type input`bucket;
        '`$"Second argument of timebar must be of type -11h"];
    if[not -11h~type input`timecol;
        '`$"Third argument of timebar must be have type -11h"];
    :dict;
  };

// check that filters parameter is of type dictionary, has symbol keys, the values are 
// in (where function;value(s)) pairs and (not)within filtering functions have two values
// associated with it.
checkfilters:{[dict;parameter]
    example:"`sym`bid`ask!(enlist(=;`AAPL);((<;85);(>;60));enlist(not;within;10 20))";
    dict:checktype[99h;dict;parameter];
    input:dict parameter;
    if[not 11h~abs type key input;
        '`$"Filters parameter key must be of type 11h - example:",example];
    filterpairs:raze value input;
    if[any not in[count each filterpairs;2 3];
        '`$"Filters parameter values must be paired in the form (filter function;value(s)) or a list of three of the form (not;filter function;value(s)) - example: ",example];
    if[15 in value each first each filterpairs where 3=count each filterpairs;
        '`$"Filters parameter values containing three elements must have the first element being the not keyword - example ",example];
    allowedops:(<;>;<>;in;within;like;<=;>=;=;~;not);
    allowednot:(within;like;in);
    nots:where(~:)~/:ops:first each filterpairs;
    notfilters:@\:[;1]filterpairs nots;
    if[not all in[ops;allowedops];'`$"Allowed operators are: =, <, >, <=, >=, in, within, like. The last three may be preceeded with 'not' e.g. (not within;80 100)"];
    if[not all in[notfilters;allowednot];'`$"The 'not' keyword may only preceed the operators within, in and like."];
    .checkinputs.withincheck'[filterpairs];
    .checkinputs.inequalitycheck'[filterpairs];
    :dict;
  };

withincheck:{[pair]
    example:"`sym`bid`ask!(enlist(=;`AAPL);((<;85);(>;60));enlist(within;10 20))";
    if[(("within"~string first pair)| "within[~:]"~string first pair)& 2<>count last pair;
        '`$"(not)within statements within the filter parameter must contain exatly two values associated with it - example: ",example];};

inequalitycheck:{[pair]
    example:"`sym`bid`ask!(enlist(=;`AAPL);((<;85);(>;60));enlist(within;10 20))";
    errmess:"The use of inequalities in the filter parameter warrants only one value - example: ",example;
    errmess2:"The use of equalities in the filter parameter warrants only one value - example: ",example;
    if[(("~<"~string first pair)|(enlist"<")~string first pair)& 1<>count last pair;
        '`$errmess2];
    if[(("~>"~string first pair)|(enlist">")~string first pair)& 1<>count last pair;
        '`$errmess2];
    if[(((enlist"=")~string first pair)|(enlist"~")~string first pair)&1<>count last pair;
        '`$errmess2];
    if[("~="~string first pair)&1<>count last pair;
        '`$errmess];};

// check that ordering parameter contains only symbols and is paired in the format
// (direction;column).
checkordering:{[dict;parameter]
    example:"((`asc`sym);(`desc`price))";
    example2:"enlist(`asc`maxPrice)";
    input:dict parameter;
    if[11h<>type raze input;
        '`$"Ordering parameter must contain pairs of symbols as its input - example: ",example];
    if[0<>count except[count each input;2];
        '`$"Ordering parameter's values must be paired in the form (direction;column) - example: ",example];
    if[0<>count except[first each input;`asc`desc];
        '`$"The first item in each of the ordering parameter's pairs must be either `asc or `desc - example: ",example];
    $[in[`grouping;key dict];grouping:(dict`grouping),();grouping:()];
    $[in[`timebar;key dict];timebar:(dict`timebar);timebar:()];
    if[in[`aggregations;key dict];
        aggs:dict`aggregations;
        aggs:flip(key[aggs]where count each get aggs;raze aggs);
        names:{
        if[1=count x[1];
            :`$(string x[0]),@[string x[1];0;upper]];
        if[2=count x[1];
            :`$(string x[0]),(@[string first x[1];0;upper]),@[string last x[1];0;upper]]
        }'[aggs];
        if[any raze {1<sum y=x}[last each aggs]'[last each input];
            '`$"Ordering parameter vague. Ordering by a column that aggregated more than once, as such the aggregation must be specified. The aggregation convention is camel-case, so to order by the aggregation max price, the following would be used: ",example2];
        if[any not in[last each input;names,grouping,timebar[2],last each aggs];
            '`$"Ordering parameter contains column that is not defined by aggregations, grouping or timebar parameter"]];
    if[in[`columns;key dict];
        columns:(dict`columns),();
        if[not (enlist `)~columns;
            if[any not in[last each input;columns];
                badorder:sv[",";string (last each input) where not in[last each input;columns]]; 
                '`$"Trying to order by column(s): ",badorder," that is not defined in the columns argument"]]];
    :dict;};
    
// check that the instrumentcol parameter is of type symbol
checkinstrumentcolumn:{[dict;parameter]:checktype[-11h;dict;parameter];};

checkunaryfunc:{[dict;parameter]
    dict:checktype[100h;dict;parameter];
    if[1<>count (get dict parameter)[1];
        '`$"Postback argument must be a function that takes in one argument only - the argument can be named anything through function signature but must represent the returned results of all other inputs"];
    :dict;};

isstring:{[dict;parameter]:checktype[10h;dict;parameter];};

checktype:{[validtypes;dict;parameter]
    inputtype:type dict parameter;
    if[not any validtypes~\:inputtype;'`$.checkinputs.formatstring["{parameter} input type incorrect - valid type(s):{validtypes} - input type:{inputtype}";`parameter`validtypes`inputtype!(parameter;validtypes;inputtype)]];
    :dict;
    };

isbool:{[dict;parameter]dict:checktype[-1h;dict;parameter];};


checkpostback:{[dict;parameter]
    if[()~dict parameter;:dict];
    if[not `sync in key dict;'`$"Postback only allowed for async requests"]
    if[not dict`sync;'`$"Postback only allowed for async requests"]
    :checkunaryfunc[dict;parameter]};

checktimeout:{[dict;parameter]
    checktype[-16h;dict;parameter];
    :dict};

.aqrest.execute:{[req;props] @[value;req;{(neg .z.w)(.gw.formatresponse[0b;0b;"error: ",x])}]};

.gw.formatresponse:{[status;sync;result] $[sync and not status; 'result; `status`result!(status;result)]};

\d .dataaccess

enableqrest:{[].gw.formatresponse::{[status;sync;result] $[sync and not status; 'result; `status`result!(status;result)]}};
disableqrest:{[] .gw.formatresponse::{[status;sync;result]$[not[status]and sync;'result;result]}};

//Gets the json and converts to input dict before executing .dataaccess.getdata on the input
qrest:{getdata jsontodict x};

// Converts json payload to .dataaaccess input dictionary
jsontodict:{
    // convert the input to a dictionary 
    dict:.j.k x;
    k:key dict;
    // Change the Type of `tabname`instruments`grouping to chars
    dict:@[dict;`tablename`instruments`grouping`columns inter k;{`$x}];
    // Change the Type of `start/end time to timestamps (altering T -> D and - -> . if applicable)
    dict:@[dict;`starttime`endtime inter k;{x:ssr[x;"T";"D"];x:ssr[x;"-";"."];value x}];
    // retrieve aggregations
    if[`aggregations in k;dict[`aggregations]:value dict[`aggregations]];
    // Convert timebar
    if[`timebar in k;dict[`timebar]:@[value dict[`timebar];1+til 2;{:`$x}]];
    // Convert the filters key
    if [`filters in k;dict[`filters]:filterskey dict`filters];
    //output
    :dict}

convertingdict:(like;in)!`string`symbol

filterskey:{[filtersstrings]
    // Convert the string to a dict
    dict:value filtersstrings;
    // Undergo the filter list
    :@[dict;key dict;multifilterfunc]
    };

multifilterfunc:{
    if[x~raze x;:filterfunc x];
    :filterfunc each x};

filterfunc:{
    // If there's a ~ error as types can't pass through qrest yet
    if[~[~;x[0]];'`$"Can't pass ~ through qREST filters please use freeformwhere"];
    // If there is a like convert the argument to a string
    if[~[like;x[0]];A:string x[1];A:ssr[A;"6";"^"];A:ssr[A;"9";"["];A:ssr[A;"0";"["];A:ssr[A;"1";"?"];A:ssr[A;"8";"*"];:(like;A)];
    // Otherwise just use the input
    :x};

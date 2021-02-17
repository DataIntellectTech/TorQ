.aqrest.execute:{[req;props] @[value;req;{(neg .z.w)(.gw.formatresponse[0b;0b;"error: ",x])}]};
\d .dataaccess

enableqrest:{[].gw.formatresponse::{[status;sync;result] $[sync and not status; 'result; `status`result!(status;result)]}};
disableqrest:{[] .gw.formatresponse::{[status;sync;result]$[not[status]and sync;'result;result]}};


// Converts json payload to .dataaaccess input dictionary
jsontodict:{
    // convert the input to a dictionary
    dict:.j.k x;
    k:key dict;
    // Change the Type of `tabname`instruments`grouping to chars
    dict:@[dict;`tablename`instruments`grouping`aggregations`columns inter k;{`$x}];
    // Change the Type of `start/end time to timestamps (altering T -> D and - -> . if applicable)
    dict:@[dict;`starttime`endtime inter k;{x:ssr[x;"T";"D"];x:ssr[x;"-";"."];value x}];
    // Convert timebar
    if[`timebar in k;dict[`timebar]:@[dict[`timebar];1+til 2;{:`$x}]];
    //output
    :dict}

qrest:{:agetdata jsontodict x};

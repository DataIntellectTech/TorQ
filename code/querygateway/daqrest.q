\d .dataaccess

// .gw.formatresponse:{[status;sync;result]$[not[status]and sync;'result;result]}};

//Gets the json and converts to input dict before executing .dataaccess.getdata on the input
qrest:{
    // Set the response type
    .gw.formatresponse:{[status;sync;result] $[sync and not status; 'result; `status`result!(status;result)]};
    // Run the function 
    :getdata jsontodict x};
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
    :dict};

quotefinder:{y[2#where y>x]}

filterskey:{[filtersstrings]
    likelist:ss[filtersstrings;"like"];
    if[0=count likelist;value filtersstrings];
    // Get the location of all the backticks
    apostlist:ss[filtersstrings;"'"];
    // Get the location of all the likes
    swaplist:raze {y[2#where y>x]}[;apostlist] each likelist;
    // Swap the ' to "
    filtersstrings:@[filtersstrings;swaplist;:;"\""];
    // Convert the string to a dict
    :value filtersstrings
    };

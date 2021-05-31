\d .kxdash
enabled:@[value;`enabled;{0b}];

// use this to store the additional params that the kx dashboards seem to send in
dashparams:`o`w`r`limit!(0;0i;0i;0W)

// function to be called from the dashboards
dashexec:{[q;s;j]
 .gw.asyncexecjpt[(dashremote;q;dashparams);(),s;dashjoin[j];();0Wn]
 }

// execute the request
// return a dict of status and result, along with the params
// add a flag to the start of the list to stop dictionaries collapsing
// to tables in the join function
dashremote:{[q;dashparams]
 (`kxdash;dashparams,`status`result!@[{(1b;value x)};q;{(0b;x)}])
 }

// join function used for dashboard results
dashjoin:{[joinfunc;r]
 $[min r[;1;`status];
  (`.dash.rcv_msg;r[0;1;`w];r[0;1;`o];r[0;1;`r];r[0;1;`limit] sublist joinfunc r[;1;`result]);
  (`.dash.snd_err;r[0;1;`w];r[0;1;`r];r[0;1;`result])]
 }

dashps:{
 // check the query coming in meets the format
 $[@[{`f`w`r`x`u~first 1_ value first x};x;0b];
   // pull out the values we need to return to the dashboards
   [dashparams::`o`w`r`limit!(last value x 1;x 2;x 3;x[4;0]);
    // execute the query part, which must look something like
    // .kxdash.dashexec["select from t";`rdb`hdb;raze]
    value x[4;1];
    ];
   //
   value x]
 }


// need this to handle queries that only hit one backend process
// reformat those responses to look the same
formatresponse:{[status;sync;result]
  if[`kxdash~first result;
  res:last result;
  :$[res`status;
    (`.dash.rcv_msg;res`w;res`o;res`r;res`result);
    (`.dash.snd_err;res`w;res`r;res`result)]];
 $[not[status]and sync;'result;result]}


init:{
 // KX dashboards are expecting getFunctions to be defined on the process
 .api.getFunctions:@[value;`.api.getFunctions;{{:()}}];
 // Reset format response
 .gw.formatresponse:formatresponse;
 // incorporate dashps into the .z.ps definition
 .z.ps:{x@y;.kxdash.dashps y}@[value;`.z.ps;{{value x}}];
 };
 
if[enabled;init[]];

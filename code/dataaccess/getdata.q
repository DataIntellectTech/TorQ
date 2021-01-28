// high level api functions for data retrieval

getdata:{[inputparams]                                                                       // [input parameters dict] generic function acting as main access point for data retrieval
  inputparams:.dataaccess.checkinputs inputparams;                                           // validate input passed to getdata
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];                         // extract validated parameters from input dictionary
  query:.queryorder.orderquery queryparams;                                                  // re-order the passed parameters to build an efficient query
  table:raze value each query;                                                               // execute the queries
  f:{[input;x;y]y[x] input};
  if[not 0~count (queryparams`ordering);
    table:f[table;;queryparams`ordering]/[1;last til count (queryparams`ordering)]];         // order the query after it's fetched
  :queryparams[`renamecolumn] xcol table;                                                    // rename the columns
  $[in[`postback;key inputparams];                                                           // apply post-processing function
    :.eqp.processpostback[result;inputparams`postback];
    :result];
  };

\d .dataaccess

buildquery:{[inputparams]
  inputparams:.dataaccess.checkinputs inputparams;                                           
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];                         
  :.queryorder.orderquery queryparams}; 


// high level api functions for data retrieval

getdata:{[inputparams]                                                                       // [input parameters dict] generic function acting as main access point for data retrieval
  inputparams:.dataaccess.checkinputs inputparams;                                           // validate input passed to getdata
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];                         // extract validated parameters from input dictionary
  query:.queryorder.orderquery queryparams;                                                  // re-order the passed parameters to build an efficient query
  table:raze value each query;                                                               // execute the queries
  if[not 0~count queryparams`ordering;table:{(queryparams`ordering)[x]table} 0];
  :queryparams[`renamecolumn] xcol table;                                                    // rename the columns
  $[in[`postback;key inputparams];                                                           // apply post-processing function
    :.eqp.processpostback[result;inputparams`postback];
    :result];
  };

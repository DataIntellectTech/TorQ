// high level api functions for data retrieval

getdata:{[inputparams]                                                                       // [input parameters dict] generic function acting as main access point for data retrieval
  inputparams:.checkinputs.checkinputs inputparams;                                          // validate input passed to getdata
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];                         // extract validated parameters from input dictionary
  query:.queryorder.orderquery queryparams;                                                  // re-order the passed parameters to build an efficient query
  :executequery query;                                                                       // execute query
 };

executequery:{[query]
  //:exec raze .servers.gethandlebytype\:[proctype;`any]@'query from query;
  :0i
 };

//- generic 'getdata' function

getdata:{[inputparams]
  inputparams:.checkinputs.checkinputs inputparams;
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];
  query:.queryorder.orderquery queryparams;
  :executequery query;
 };

executequery:{[query]
  :get query[0;`query];
 };

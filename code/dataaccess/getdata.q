// high level api functions for data retrieval

getdata:{[inputparams]                                                                       // [input parameters dict] generic function acting as main access point for data retrieval
  if[1b~inputparams`getquery;:.dataaccess.buildquery[inputparams]]
  inputparams:.dataaccess.checkinputs usersdict:inputparams;                                 // validate input passed to getdata
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];                         // extract validated parameters from input dictionary
  query:.queryorder.orderquery queryparams;                                                  // re-order the passed parameters to build an efficient query
  table:raze value each query;                                                               // execute the queries
  if[(.proc.proctype=`rdb);
    deftime:.checkinputs.getdefaulttime dict;
    if[(`$(string deftime),".date") in (cols table);
      table:({$[(`$(string deftime),".date")<>x;x;`date]} each (cols table)) xcol table];    // change defaulttime.date to date on rdb process query result
    if[(1 < count inputparams`procs) & (all (cols inputparams`tablename) in (cols table));   // adds date column when all columns are
        table:update date:.z.d from table;                                                   // quried from the rdb process for both
      if[98h=type table;table:`date xcols table]                                             // keyed and unkeyed results
      if[99h=type table;keycol:cols key table;
        table:0!table;
        table:`date xcols table;
        table:keycol xkey table]];
  ];
  f:{[input;x;y]y[x] input};
  if[not 0~count (queryparams`ordering);
    table:f[table;;queryparams`ordering]/[1;last til count (queryparams`ordering)]];         // order the query after it's fetched
  result:queryparams[`renamecolumn] xcol table;                                              // rename the columns
  if[10b~`head`procs in key inputparams;result:select [inputparams`head] from result];
  .requests.logger[usersdict;result];
  $[in[`postback;key inputparams];                                                           // apply post-processing function
    :.eqp.processpostback[result;inputparams`postback];
    :result];
  };

\d .dataaccess

buildquery:{[inputparams]
  inputparams:.dataaccess.checkinputs inputparams;                                           
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];
  if[`procs in key inputparams;:(.proc.proctype,.queryorder.orderquery queryparams)]; 
  :.queryorder.orderquery queryparams}; 


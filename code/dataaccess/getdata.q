// high level api functions for data retrieval


getdata:{[inputparams]
  if[.proc.proctype in key inputparams;inputparams:inputparams .proc.proctype];
  requestnumber:.requests.initlogger[inputparams];
// [input parameters dict] generic function acting as main access point for data retrieval
  if[1b~inputparams`getquery;:.dataaccess.buildquery[inputparams]];
  // validate input passed to getdata
  usersdict:inputparams;
  inputparams:@[.dataaccess.checkinputs;inputparams;.requests.error[requestnumber;]];
  // log success of checkinputs 
  .lg.o[`getdata;"getdata Request Number: ",(string requestnumber)," checkinputs passed"];
  // extract validated parameters from input dictionary
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];
  // log success of eqp
  .lg.o[`getdata;"getdata Request Number: ",(string requestnumber)," extractqueryparams passed"];  
  // re-order the passed parameters to build an efficient query  
  query:.queryorder.orderquery queryparams;
  // log success of queryorder
  .lg.o[`getdata;"getdata Request Number: ",(string requestnumber)," queryorder passed"];
  // execute the queries                                                    
  table:raze value each query;                                                               
  if[(.proc.proctype=`rdb);
  // change defaulttime.date to date on rdb process query result
    if[(`$(string .checkinputs.getdefaulttime inputparams),".date") in (cols table);
      table:?[(cols table)<>`$(string .checkinputs.getdefaulttime[inputparams]),".date";cols table;`date] xcol table];
  // adds partition column when all columns are quried from the rdb process for both keyed and unkeyed results
    if[(1 < count inputparams`procs) & (all (cols inputparams`tablename) in (cols table));
        //get appropriate column name based on partition type
         colname:$[-7h~type .rdb.getpartition[];`int;`date];
        //update table to include col of current partition value
        table:![table;();0b;enlist[colname]!(), .rdb.rdbpartition];
      if[98h=type table;table:colname xcols table];
      if[99h=type table;keycol:cols key table;
        table:0!table;
        table:colname xcols table;
        table:keycol xkey table]];
  ];
  f:{[input;x;y]y[x] input};
// order the query after it's fetched
  if[not 0~count (queryparams`ordering);
    table:f[table;;queryparams`ordering]/[1;last til count (queryparams`ordering)]];         
// rename the columns  
  result:queryparams[`renamecolumn] xcol table; 
// apply post-processing function if called in process or query to single process called from gateway
    if[(10b~in[`postprocessing`procs;key inputparams])or((1b~`postprocessing in key inputparams)and(1~count inputparams `procs));
        result:.eqp.processpostback[result;inputparams`postprocessing]];
// apply sublist function if called in process or query to single process called from gateway                                             
  if[(10b~`sublist`procs in key inputparams)or((1b~`sublist in key inputparams)and(1~count inputparams `procs));
        result:(inputparams`sublist) sublist result];
   .requests.updatelogger[requestnumber;`endtime`success!(.proc.cp[];1b)];
   :result
  };

\d .dataaccess

buildquery:{[inputparams]
  if[.proc.proctype in key inputparams;inputparams:inputparams .proc.proctype];
  inputparams:.dataaccess.checkinputs inputparams;                                           
  queryparams:.eqp.extractqueryparams[inputparams;.eqp.queryparams];
  if[`procs in key inputparams;:(.proc.proctype,.queryorder.orderquery queryparams)]; 
  :.queryorder.orderquery queryparams}; 


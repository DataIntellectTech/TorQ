\d .datareplay

// Generate times between two input times in p intervals
getBuckets:{[s;e;p](s+p*til(ceiling 1+e%p)-(ceiling s%p))}

//  params[`t] is table data
//  params[`tc] is time column to cut on
//  params[`tn] is table name
//  params[`interval] is the time interval to bucket the messages into.
tableDataToDataStream:{[params]
  // Sort table by time column.
  params[`t]:params[`tc] xasc delete date from params[`t];
  
  // get all times from table
  t_times:params[`t][params[`tc]];

  $[not null params[`interval];
    [ // if there is an interval, bucket messages into this interval
      // make bukets of ten second intervals
      times:getBuckets[params[`sts];params[`ets];params[`interval]];
       
      // put start time in fornt of t_times
      t_times:params[`sts],t_times;

      //Get places to cut
      cuts:distinct t_times bin times;
      cuts:cuts where cuts>-1;
      
      // fill first cut
      if[0<>first cuts;cuts:0,cuts];
     
      //cut table by time interval
      msgs:cuts cut params[`t];
 
      // get times that match data
      time:{first x[y]}[;params[`tc]] each msgs;

      // Return table of times and message chunks
      -1_([]time:time;msg:{(`upd;x;y)}[params[`tn]] each msgs)
    ];
    // if there is no intevral, cut by distinct time.
    ([]
      time:distinct t_times;
      msg:{(`upd;x;$[1<count y;flip y;first y])}[params[`tn]] each 
          (where differ t_times) cut params[`t]
    )
  ]
        
 };


// params[`h] is handle to hdb process
// params[`tn] is table name used to query hdb
// params[`syms] is list of instruments to get
// params[`where] is an additional where clause in functional form - Not Reuqired
// params[`sts] is start of time window to get
// params[`ets] is end of time window to get
tableToDataStream:{[params]

  // Build where clause
  wherec:(enlist (within;`date;(enlist;`date$params[`sts];`date$params[`ets]))) // date in daterange
            ,$[count params[`syms];enlist (in;`sym;enlist params[`syms]);()] //if syms is empty, omit sym in syms
            ,$[count params[`where];params[`where];()] // custom where clause (optional)
            ,enlist (within;params[`tc];(enlist;params[`sts];params[`ets])); // time within (sts;ets)
  
  // Have hdb evaluate select statement.
  t:@[params[`h];
      (eval;(?;params[`tn];enlist wherec;0b;()));
      {.lg.e[`dataloader;"Failed to evauluate query on hdb: ",x]}
     ];

  tableDataToDataStream[params,enlist[`t]!enlist t]
 };

// params[`sts] is start of time window to get
// params[`ets] is end of time window to get
// params[`tp] is the inrement between times
// params[`timerfunc] is the timer function to use
getTimers:{[params]
 times:getBuckets[params[`sts];params[`ets];params[`interval]];
 ([]time:times;msg:params[`timerfunc],'times)
 }


// params[`tabs] is list of tables to get - Required
// params[`sts] is start of time window to get - Required
// params[`ets] is end of time window to get - Required
// params[`syms] is list of instruments to get - Default all syms
// params[`where] is an additional where clause in functional form - Not Reuqired
// params[`timer] is whether or not to retrieve timer - Default 0b
// params[`h] is handle to hdb - Default 0 (self)
// params[`interval] is the time interval to bucket the messages into. - Not Required
// prarms[`tc] is the time column of the tables specified - Defualt `time
// params[`timerfunc] is the timer function to use in timer messages - Default `.z.ts
tablesToDataStream:{[params]
  defaults:`timer`h`syms`interval`tc`timerfunc`where!(0b;0;`symbol$();`timespan$0n;`time;`.z.ts;());
  params:defaults,params;

  // check for default parameters `tabs`sts`ets
  if[count missing:`tabs`sts`ets except key params;'"mising prameters: "," " sv string missing;];
  params[`tabs]:(),params[`tabs];

  ds:raze {tableToDataStream x,(enlist `tn)!enlist y}[params] each params[`tabs];

  $[params[`timer];
    `time xasc ds,getTimers[params,enlist[`interval]! enlist $[null k:params[`interval];0D00:00:10.00;k]];
    `time xasc ds]
  };

\d .

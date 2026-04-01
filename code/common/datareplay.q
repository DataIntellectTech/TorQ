\d .datareplay

// params[`tabs] is list of tables to get - Required
// params[`sts] is start of time window to get - Required
// params[`ets] is end of time window to get - Required
// params[`syms] is list of instruments to get - Default all syms
// params[`where] is an additional where clause in functional form - Not Required
// params[`timer] is whether or not to retrieve timer - Default 0b
// params[`h] is handle to hdb - Default 0 (self)
// params[`replayinterval] is the interval to bucket the data messages into - Default no bucketing, messages published as per data timestamps
// params[`timerinterval] is the interval to bucket the timer messages into - Default 10 seconds, only used if timer is true
// prarms[`tc] is the time column of the tables specified - Default `time
// params[`timerfunc] is the timer function to use in timer messages - Default `.z.ts
tablestodatastream:{[params]
  defaults:`timer`h`syms`replayinterval`timerinterval`tc`timerfunc`where!(0b;0;`symbol$();`timespan$0n;`timespan$0n;`time;`.z.ts;());
  params:defaults,params;

  // Check for default parameters `tabs`sts`ets
  if[count missing:`tabs`sts`ets except key params;'"missing parameters: "," " sv string missing;];
  params[`tabs]:(),params[`tabs];

  ds:raze {tabletodatastream x,(enlist `tn)!enlist y}[params] each params[`tabs];
  
  $[params[`timer];
    `time xasc ds,gettimers[params,enlist[`timerinterval]! enlist $[null k:params[`timerinterval];0D00:00:10.00;k]];
    `time xasc ds]
  };

// Generate times between two input times in p intervals
getbuckets:{[s;e;p](s+p*til(ceiling 1+e%p)-(ceiling s%p))};

//  params[`t] is table data
//  params[`tn] is table name
tabledatatodatastream:{[params]
  // Sort table by time column.
  params[`t]:params[`tc] xasc delete date from params[`t];
  
  // Get all times from table
  t_times:params[`t][params[`tc]];

  $[not null params[`replayinterval];
    [ // If there is an interval, bucket messages into this interval
      // Make buckets of ten second intervals
      times:getbuckets[params[`sts];params[`ets];params[`replayinterval]];
       
      // Put start time in front of t_times
      t_times:params[`sts],t_times;

      // Get places to cut
      cuts:distinct t_times bin times;
      cuts:cuts where cuts>-1;
      
      // Fill first cut
      if[0<>first cuts;cuts:0,cuts];
     
      // Cut table by time interval
      msgs:cuts cut params[`t];
 
      // Get times that match data
      time:{first x[y]}[;params[`tc]] each msgs;

      // Return table of times and message chunks
      -1_([]time:time;msg:{(`upd;x;y)}[params[`tn]] each msgs)
    ];
    // If there is no interval, cut by distinct time.
    ([]
      time:distinct t_times;
      msg:{(`upd;x;y)}[params[`tn]] each 
          (where differ t_times) cut params[`t]
    )
  ] 
  };

tabletodatastream:{[params]
  // Evaluate select statement in HDB
  t:@[params[`h];
      (eval;tableselectstatement params);
      {.lg.e[`dataloader;"Failed to evauluate query on hdb: ",x]}
     ];

  tabledatatodatastream[params,enlist[`t]!enlist t]
 };

tableselectstatement:{[params]
  // Build where clause
  wherec:(enlist (within;`date;(enlist;`date$params[`sts];`date$params[`ets]))) // date in daterange
            ,$[count params[`syms];enlist (in;`sym;enlist params[`syms]);()] //if syms is empty, omit sym in syms
            ,$[count params[`where];params[`where];()] // custom where clause (optional)
            ,enlist (within;params[`tc];(enlist;params[`sts];params[`ets])); // time within (sts;ets)

  (?;params[`tn];enlist wherec;0b;())
 };

gettimers:{[params]
  times:getbuckets[params[`sts];params[`ets];params[`timerinterval]];
  ([]time:times;msg:params[`timerfunc],'times)
  };

\d .

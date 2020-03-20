\d .dqc

pctAvgDailyChange:{[fname;tabname;rt;ndays;thres]
  .lg.o[`pctAvgDailyChange;"Checking daily average change"];  
  if[ndays>-1+count .Q.pv; :(0b;"error: number of days exceeds number of available dates")];
  previous:select avg resvalue from rt where date in (-1+last date;(-1)*(ndays)+last date),funct=fname,table=tabname;
  current:select avg resvalue from rt where date=(last date),funct=fname,table=tabname;
  $[previous[0;`resvalue]=thres*current[0;`resvalue];
    (1b;"count doesn't exceed average");
    (0b;"count exceeds average")]
  }

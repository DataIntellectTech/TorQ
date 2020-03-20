\d .dqc

pctAvgDailyChange:{[fname;tabname;rt;ndays;thres]
  .lg.o[`pctAvgDailyChange;"Checking daily average change"];  
  if[ndays>-1+count .Q.pv; :(0b;"error: number of days exceeds number of available dates")];
  previous:select avg resvalue from rt where date in (-1+last date;(-1)*(ndays)+last date),funct=fname,table=tabname;
  current:select avg resvalue from rt where date=(last date),funct=fname,table=tabname;
  $[(abs current[0;`resvalue]- previous[0;`resvalue])<=thres*previous[0;`resvalue];
    (1b;"count doesn't differ from ",(string ndays)," days average by more than ",(string thres)," percent");
    (0b;"count differs from ",(string ndays)," days average by more than ",(string thres)," percent")]
  }

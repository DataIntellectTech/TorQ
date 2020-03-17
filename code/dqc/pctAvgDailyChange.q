\d .dqc

/pctAvgDailyChange:{[fname;tabname;ndays;thres]
pctAvgDailyChange:{[fname;tabname;rt;ndays;thres]
  /hpath:`$system"pwd";
  /dbname:`$("/" sv ("dqe";"dqedb";"database"));
  /dqedbdir:.Q.dd[hsym hpath; dbname];
  /system"l ",.os.pth dqedbdir;
  /previous:select avg resvalue from resultstab where date in (-1+last date;(-1)*ndays+last date),funct=fname,table=tabname;
  /current:select avg resvalue from resultstab where date in (last date),funct=fname,table=tabname;
  /if[previous[0;`resvalue]=thres*current[0;`resvalue]; .lg.o[`analytics;"count doesn't exceed average"]; :1b];
  previous:select avg resvalue from rt where date in (-1+last date;(-1)*ndays+last date),funct=fname,table=tabname;
  current:select avg resvalue from rt where date in (last date),funct=fname,table=tabname;
  $[previous[0;`resvalue]=thres*current[0;`resvalue];"matched";"did not match"]
  }

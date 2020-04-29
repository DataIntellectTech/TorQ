\d .dqc

/- Check that current result of a given function applied to a given table is 
/- within threshold limits of n days average taken from results table.
/- Parameters: fname - name of function from dqe engine; tabname - name of
/- table; rt - results table in dqedb; ndays - number of previous days to
/- compute daily average; thres - threshold is a number from 0 to 1 that
/- corresponds to a range from 0% to 100%

pctAvgDailyChange:{[fname;tabname;rt;ndays;thres]                                       
  .lg.o[`pctAvgDailyChange;"Checking daily average change"];  
  if[ndays>-1+count .Q.pv; :(0b;"error: number of days exceeds number of available dates")];
  previous:select avg resvalue from rt where date in (-1+last date;(-1*ndays)+last date),funct=fname,table=tabname;
  current:select avg resvalue from rt where date=last date,funct=fname,table=tabname;
  c:abs[current[0;`resvalue]- previous[0;`resvalue]]<=thres*previous[0;`resvalue];
  (c;"count ",$[c;"doesn't differ";"differs"]," from ",(string ndays)," days average by more than ",(string thres),"%")
  }

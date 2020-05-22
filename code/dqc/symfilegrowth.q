\d .dqc

/- Take the average symfile count from the past n days, then check that todays
/- sym file count hasn't grown more than pct%. Third argument (weekends) is a
/- boolean flagging if you should consider weekends (1b) or not (0b).
symfilegrowth:{[ndays;pct;weekends]
  .lg.o[`symfilegrowth;"Checking sym file has not grown more than ",string[pct],"%."];
  /- Create list of last n days.
  lastndays:$[weekends;.z.D+-1*1+til ndays;{x#a where((a:.z.D-1+til 7*1+x div 5)mod 7)in 2 3 4 5 6}ndays];
  /- Get handle to the DQEDB.
  h:(exec first w from .servers.getservers[`proctype;`dqedb;()!();0b;1b]);
  /- Make sure we have all previous n (business) days in the dqedb.
  if[ndays>c:count lastndays inter@[h;".Q.pv";`date$()];:(0b;"ERROR: number of",$[weekends;" ";" business "],"days (",string[ndays],") exceeds number of available dates (",string[c],") on disk")];
  /- Get todays sym file count.
  tc:first exec resvalue from .dqe.resultstab where funct=`symcount;
  /- Get average sym file count from previous days.
  ac:exec avg resvalue from h"select from resultstab where date in ",(" "sv string lastndays),",funct=`symcount";
  /- Test whether the symfile growth is less than a pct, and return test status.
  msg:"Sym file ",$[b:pct>100*(tc-ac)%ac;"has not";"has"]," grown more than ",string[pct],"% above the previous ",string[ndays],"-day average.";
  .lg.o[`symfilegrowth;msg];
  (b;msg)
  }

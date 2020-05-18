\d .dqc

/- Take the average symfile count from the past n days, then check that todays
/- sym file count hasn't grown more than pct%.
symfilegrowth:{[ndays;pct]
  .lg.o[`dqe;"Checking sym file has not grown more than ",string[pct],"%."];
  /- Get handle to the DQEDB.
  h:(exec first w from .servers.getservers[`proctype;`dqedb;()!();0b;1b]);
  /- Make sure we have enough days in the dqedb.
  if[ndays>h"count .Q.pv";:(0b;"ERROR: number of days (ndays) exceeds number of available dates")];
  /- Get todays sym file count.
  tc:first exec resvalue from .dqe.resultstab where funct=`symcount;
  /- Get average sym file count from previous days.
  ac:exec avg resvalue from h"select from resultstab where date>=.z.d-",string[ndays],",funct=`symcount";
  /- Test whether the symfile growth is less than a pct, and return test status.
  (b;"Sym file ",$[b:pct>100*(tc-ac)%ac;"has not";"has"]," grown more than ",string[pct],"% above the previous ",string[ndays],"-day average.")
  }

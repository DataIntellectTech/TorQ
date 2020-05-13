\d .dqc

/- Take the average symfile count from the past n days, then check that todays
/- sym file count hasn't grown more than pct%.
symfilegrowth: {[directory;ndays;pct]
  /- Get handles to the DQE and the DQEDB. 
  h:first exec w from .servers.SERVERS where proctype=`dqedb;
  / Make sure we have enough days in the dqedb.
  if[ndays>h"count .Q.pv";:(0b;"ERROR: number of days (ndays) exceeds number of available dates")];
  / Get todays sym file count.
  tc:dqeh"first exec resvalue from .dqe.resultstab where funct=`symcount";
  /- Get average sym file count from previous days, where select statement is
  /- "select from resultstab where date>=.z.d-ndays,funct=`symfilecheck"
  ac:exec avg resvalue from dqedbh(?;`resultstab;(((';~:;<);`date;(-;`.z.d;ndays));(=;`funct;enlist`symcount));0b;());
  (1b;"Sym file ",$[pct<100*(tc-ac)%ac;"has";"has not"]," grown more than ",string[pct],"% in the last ",string[ndays]," days.")
  }

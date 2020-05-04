\d .dqc

/- check that a table has obtained records within a specified period of time
tableticking:{[tab;timeperiod;timetype]
  .lg.o[`dqc;"checking table recieved data in the last ",string[timeperiod]," ",string[timetype],"s"];
  $[0<a:count select from tab where time within (.z.p-timetype$"J"$string timeperiod;.z.p);
    (1b;"there are ",(string a)," records");
    (0b;"the table is not ticking")]
  }

\d .dqc

/ Takes a table name tn and two column names ca and cb, as well as a percentage
/ pt and a tolerance tl as a timespan (eg 0D00:00:00.001).
timediff:{[tn;ca;cb;pt;tl]
  .lg.o[`timediff;"Checking the time differences in columns ",(", "sv string(ca;cb))," of table ",(string tn)];
  ot:$[pt>re:(sum a)%count a:tl<(tn ca)-tn cb;
    (1b;"No major problem with data flow");
    (0b;"ERROR: ",(string re*100),"% of differences between columns ",(string ca),", ",m:(string cb)," are greater than the timespan ",(string tl),".")
    ];
  .lg.o[`timediff;ot 1];
  ot
  }

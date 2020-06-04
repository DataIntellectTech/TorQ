\d .dqc

/ Takes a table name tn and two column names ca and cb, as well as a percentage
/ pt and a tolerance tl in milliseconds.
timediff:{[tn;ca;cb;pt;tl]
  .lg.o[`timediff;"Checking the time differences in columns ",(", "sv string(ca;cb))," of table ",(string tn)];
  ot:$[tl>re:1-(sum a)%count a:?[tn;();();(>;(0D+tl*00:00:00.001);(-;ca;cb))];
    (1b;"No major problem with data flow");
    (0b;"ERROR: ",(string re*100),"% of differences between columns ",(string ca),", ",m:(string cb)," are more than ",(string tl)," milliseconds.")
    ];
  .lg.o[`timediff;ot 1];
  ot
  }

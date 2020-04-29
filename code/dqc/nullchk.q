\d .dqc

/- Function to check the percentage of nulls in each column from colslist of a
/- table t against a threshold thres, a list of threshold percentages for each
/- column.
nullchk:{[t;colslist;thres] 
  .lg.o[`dqc;"checking ",string[t]," for nulls in columns ",", "sv string(),colslist];
  d:({sum$[0h=type x;0=count@'x;null x]}each flip tt)*100%count tt:((),colslist)#get t;
  $[count b:where d>thres;
    (0b;"Following columns above threshold: ",(", " sv string b),".");
    (1b;"No columns above threshold.")
    ]
  }

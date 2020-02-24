\d .dqc
nullchk:{[t;colslist;thres]                                                                                     /- function to check percentage of nulls in each column from colslist of a table t
  d:({sum$[0h=type x;0=count@'x;null x]}each flip tt)*100%count tt:((),colslist)#t;                             /- dictionary of nulls percentages for each column
  res:([] colsnames:key d; nullspercentage:value d);
  update thresholdfail:nullspercentage>thres from res                                                           /- compare each column's nulls percentage with threshold thres
  }

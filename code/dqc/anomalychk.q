\d .dqc
anomalychk:{[t;colslist;thres]                                                                                  /-function to check percentage of anomalies in each column from colslist of a table t
  d:({sum{any x~'(0w;-0w;0W;-0W)}'[x]}each flip tt)*100%count tt:((),colslist)#t;
  res:([] colsnames:key d; anomalypercentage:value d);
  update thresholdfail:anomalypercentage>thres from res                                                         /- compare each column's anomalies percentage with threshold thres
  }

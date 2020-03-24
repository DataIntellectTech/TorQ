\d .dqc
anomalychk:{[t;colslist;thres]
  / Check percentage of anomalies in each of the columns of t, where the columns 
  / to watch are specified in colslist, and a percentage threshold, thres.
  d:({sum{any x~'(0w;-0w;0W;-0W)}'[x]}each flip tt)*100%count tt:((),colslist)#get t;
  res:([] colsnames:key d; anomalypercentage:value d);
  $[count b:exec colsnames from res where anomalypercentage>thres;
    (0b;"Following columns above threshold: ",(", " sv string b),".");
    (1b;"No columns above threshold.")
    ]
  }

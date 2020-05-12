\d .dqc
/- Check percentage of infinities in each of the columns of t, where the columns 
/- to watch are specified in colslist, and a percentage threshold thres.
infinitychk:{[t;colslist;thres]
  .lg.o[`dqe;"checking ",string[t]," for infinities in columns ",", "sv string(),colslist];
  d:({sum x in (0w;-0w;0W;-0W)}each flip tt)*100%count tt:((),colslist)#get t;
  $[count b:where d>thres;
    (0b;"Following columns above threshold: ",(", " sv string b),".");
    (1b;"No columns above threshold.")
    ]
  }

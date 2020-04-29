\d .dqc

/- Check that values of specified columns colslist in table (name) tn are within 
/- the range defined by the tables tlower and tupper.
rangechk:{[tn;colslist;tlower;tupper;thres]
  .lg.o[`dqc;"checking columns ",(0N!", "sv string(),colslist)," of table ",string[tn]," are within specified range"];
  if[0=count colslist; :(0b; "ERROR: No columns specified in colslist.")];
  tab:get tn;
  if[1<>sum differ count each (tab;tupper;tlower);
    :(0b; "ERROR: Input tables are different lengths.")
    ]
  if[any any tupper<tlower;:(0b;"ERROR: tlower and tupper wrong way round.")]
  /- exclude columns that do not have pre-defined limits
  colslist:((),colslist) except exec c from meta tab where t in "csSC ";
  tupper:colslist#tupper;
  tlower:colslist#tlower;
  /- dictionary with results by columns
  d:sum[tt within (tlower;tupper)]*100%count tt:colslist#tab;
  $[count b:where d<thres;
    (0b;"Following columns below threshold: ",(", " sv string b),".");
    (1b;"No columns below threshold.")
    ]
  }

\d .dqc
rangechk:{[t;colslist;tlower;tupper;thres]                                                                      /- check that values are within the range defined by tlower and tupper tables
  colslist:((),colslist) except exec c from meta t where t in "csSC ";                                          /- exclude columns that do not have pre-defined limits
  tupper:colslist#tupper;
  tlower:colslist#tlower;
  d:sum[tt within (tlower;tupper)]*100%count tt:colslist#t;                                                     /- dictionary with results by columns
  res:([] colsnames:key d; inrangepercentage:value d);
  update thresholdfail:inrangepercentage<thres from res                                                         /- check if within range percentage is higher than threshold
  }

\d .dqc

/- compares the attribute of given table to expectation given in csv
attrcheck:{[tab;attribute;col]
  .lg.o[`dqe;"checking attributes on table ",string tab];
  dictmeta:exec c!a from meta tab where c in col;
  dictcheck:col!attribute;
  (c;"attribute of ",(","sv string(),col)," ",$[c:dictmeta~dictcheck;"matched";"did not match"]," expectation")
  }

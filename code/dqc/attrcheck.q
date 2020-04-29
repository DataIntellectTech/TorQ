\d .dqc

/- compares the attribute of given table to expectation given in csv
attrcheck:{[tab;attribute;col]
  .log.o[`dqe;"checking attributes on table ",string t];
  dictmeta:exec c!a from meta tab where c in col;
  dictcheck:col!attribute;
  (c;"attribute of ",(","sv string(),col)," ",$[c:dictmeta~dictcheck;"matched";"did not match"]," expectation")
  }

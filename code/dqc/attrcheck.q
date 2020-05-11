\d .dqc

/- compares the attribute of given table to expectation given in csv
attrcheck:{[tab;attribute;col]
  .lg.o[`dqe;"checking attributes on table ",string tab];
  dictmeta:exec c!a from meta tab where c in col;
  dictcheck:col!attribute;
  $[dictmeta~dictcheck;
    (1b;"attribute of ",(","sv string(),col)," matched expectation");
    (0b;"Expected attribute of column ",(","sv string(),col)," was ",(","sv string(),attribute),". Attribute of column ",(","sv string(),col)," is ",(","sv string(),value dictmeta))]
  }

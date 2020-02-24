\d .dqc
attrcheck:{[tab;attribute;col]                                // compares the attribute of given table to expectation given in csv
  metaoftab:select c,a from meta tab where c in col;
  dictmeta:metaoftab[`c]!metaoftab[`a];
  dictcheck:col!attribute;
  (c;"attribute of ",(","sv string(),col)," ",$[c:dictmeta~dictcheck;"matched";"did not match"]," expectation")
  }

\d .dqe 
attrcheck:{[tab;attribute;col]                                // compares the attribute of given table to expectation given in csv
  metaoftab:select c,a from meta tab where c in col;
  checktab:([]c:col;a:attribute);
  (c;"attribute of ",(","sv string(),col)," ",$[c:metaoftab~checktab;"matched";"did not match"]," expectation")
  }

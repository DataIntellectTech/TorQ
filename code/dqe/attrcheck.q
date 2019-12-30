\d .dqe
attrcheck:{[tab;attribute;col]
  metaoftab:select c,a from meta tab where c in col;
  checktab:([]c:col;a:attribute);
  $[metaoftab~checktab;
    (1b;"attribute of ",(string col)," in ",(string tab)," matched expectation");
    (0b;"attribute of ",(string col)," in ",(string tab)," did not match expectation")]
  }

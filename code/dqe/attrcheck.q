\d .dqe
attrcheck:{[tab;attribute;col]
  metaoftab:select c,a from meta tab where c in col;
  checktab:([]c:col;a:attribute);
  $[metaoftab~checktab;
    (1b;"attribute of ",($[1=count col;string col;"," sv string col])," matched expectation");
    (0b;"attribute of ",($[1=count col;string col;"," sv string col])," did not match expectation")]
  }

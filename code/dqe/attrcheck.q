\d .dqe
attrcheck:{[tab;attribute;col]
  $[attribute=attr tab[col];
    (1b;"attribute of ",(string col)," in ",(string tab)," matched expectation");
    (0b;"attribute of ",(string col)," in ",(string tab)," did not match expectation")]
  }

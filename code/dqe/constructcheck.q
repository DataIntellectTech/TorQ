.dqe.constructcheck:{[construct;chktype]                                                                        /- function to check for table,variable,function or view
  chkfunct:{system x," ",string $[null y;`;y]};
  dict:`table`variable`view`function!chkfunct@/:"avbf";
  .lg.o[`dqe;"checking if ", (s:string construct)," ",(s2:string chktype), " exists"];
  $[construct in dict[chktype][];
    (1b;s," ",s2," exists");
    (0b;s," ",s2," missing from process")]
  }

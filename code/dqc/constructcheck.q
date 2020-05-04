\d .dqc

/- function to check for table,variable,function or view
constructcheck:{[construct;chktype]
  chkfunct:{system x," ",string $[null y;`;y]};
  dict:`table`variable`view`function!chkfunct@/:"avbf";
  .lg.o[`dqe;"checking if ", (s:string construct)," ",(s2:string chktype), " exists"];
  c:construct in dict[chktype][];
  (c;s," ",s2," ",$[c;"exists";"missing from process"];$[chktype=`table;construct in tables[];enlist value construct])
  }

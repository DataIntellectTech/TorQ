\d .dqe
/- distinct symbols count in a table t and a column col. Works on partitioned 
/- tables in an hdb
symcount:{[t;col]
  .lg.o[`test;"Counting distinct symbols in the sym column each day in table ",string t];
  (enlist t)!enlist count ?[t; enlist(=;.Q.pf;last .Q.PV); 1b; {x!x}enlist col]
  }

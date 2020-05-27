\d .dqe
/- distinct symbols count in a table t and a column col. Works on partitioned 
/- tables in an hdb
symcount:{[t;col]
  .lg.o[`symcount;"Counting distinct symbols each day in column ",(string col)," of table ",string t];
  (enlist t)!enlist count ?[t; enlist(=;.Q.pf;last .Q.PV); 1b; {x!x}enlist col]
  }

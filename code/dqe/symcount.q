\d .dqe
/- distinct symbols count in a table tab and a column col. Works on partitioned 
/- tables in an hdb
symcount:{[tab;col]
  .lg.o[`symcount;"Counting distinct symbols each day in column ",(string col)," of table ",string tab];
  (enlist tab)!enlist count ?[tab; enlist(=;.Q.pf;last .Q.PV); 1b; {x!x}enlist col]
  }

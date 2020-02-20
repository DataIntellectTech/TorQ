\d .dqe
symcount:{[t;col]                                                                                        /distinct symbols count in a table t and a column col. Works on partitioned tables in an hdb
  (enlist t)!(enlist count ?[t; enlist(=;.Q.pf;last .Q.PV); 1b; {x!x}enlist col])
  }

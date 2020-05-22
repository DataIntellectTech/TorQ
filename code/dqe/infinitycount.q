\d .dqe

/- Given a table name as a symbol (tn), returns the number of infinities in tn.
/- Works on partitioned tables in an hdb
infinitycount:{[tn]
  lg.o[`infinitycount;"Getting count of infinities in ",string tn];
  (enlist tn)!enlist sum value ({sum x in (0w;-0w;0W;-0W)}each flip (?[tn; enlist(=;.Q.pf;last .Q.PV);1b;()]))
  }

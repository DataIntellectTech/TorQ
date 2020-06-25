\d .dqe

/- Given a table name as a symbol (tn) and a column name as a symbol (col), returns the number of nulls in col of tn.
/- Works on partitioned tables in an hdb
nullcount:{[tn;col]
  .lg.o[`nullcount;"Getting count of nulls in",$[col~`;" ";" column: ",(string col)," of "],string tn];
  (enlist tn)!enlist {sum$[0h=type x;0=count each x;null x]}?[tn;enlist(=;.Q.pf;last .Q.PV);1b;()]col
  }

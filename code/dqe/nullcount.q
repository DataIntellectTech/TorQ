\d .dqe

/- Given a table name as a symbol (tn) and a column name as a symbol (col), returns the number of nulls in col of tn.
/- Works on partitioned tables in an hdb
/- col can be set to ` for the function to work on the whole table
nullcount:{[tn;col]
  .lg.o[`nullcount;"Getting count of nulls in",$[col~`;" ";" column: ",(string col)," of "],string tn];
  (enlist tn)!enlist sum value{sum$[0h=type x;0=count each x;null x]}each flip?[tn;enlist(=;.Q.pf;last .Q.PV);1b;$[col~`;();{x!x}enlist col]]
  }

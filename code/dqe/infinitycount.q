\d .dqe

/- Given a table name as a symbol (tn), a column name as a symbol (col), returns the number of infinities in col of tn.
/- Works on partitioned tables in an hdb
infinitycount:{[tn;col]
  .lg.o[`infinitycount;"Getting count of infinities in",$[col~`;" ";" column: ",(string col)," of "],string tn];
  (enlist tn)!enlist sum value{sum x in(0w;-0w;0W;-0W)}each flip?[tn;enlist(=;.Q.pf;last .Q.PV);1b;$[col~`;();{x!x}enlist col]]
  }

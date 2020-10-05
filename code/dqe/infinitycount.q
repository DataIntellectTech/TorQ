\d .dqe

/- Given a table name as a symbol (tab), a column name as a symbol (col), returns the number of infinities in col of tab.
/- Works on partitioned tables in an hdb
infinitycount:{[tab;col]
  .lg.o[`infinitycount;"Getting count of infinities in",$[col~`;" ";" column: ",(string col)," of "],string tab];
  (enlist tab)!enlist "j"$sum value{sum x in(0w;-0w;0W;-0W)}each flip?[tab;enlist(=;.Q.pf;last .Q.PV);1b;$[col~`;();{x!x}enlist col]]
  }

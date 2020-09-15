\d .dqe

bycount:{[tab;bycols]
  .lg.o[`bycount;"Counting amount of messages received with by clauses applied to column(s) bycols"];
  (enlist$[-11h=type bycols;;` sv]bycols)!enlist?[tab;enlist(=;.Q.pf;last .Q.PV);{x!x}(),bycols;(enlist`bycount)!enlist(count;`i)]
  }

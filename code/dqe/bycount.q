\d .dqe

bycount:{[tab;bycols]
  .lg.o[`bycount;"Counting amount of messages received with by clauses applied to column(s) bycols"];
  $[0>type bycols;
    (enlist bycols)!enlist ?[tab;enlist(=;.Q.pf;last .Q.PV);{x!x}enlist bycols;(enlist `i)!enlist(count;`i)];
    (enlist ` sv bycols)!enlist ?[tab;enlist(=;.Q.pf;last .Q.PV);{x!x}bycols;(enlist `i)!enlist(count;`i)]]
  }

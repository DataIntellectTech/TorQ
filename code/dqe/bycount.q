\d .dqe

bycount:{[tab;cola;colb]
  .lg.o[`bycount;"Counting amount of messages received with by clauses applied to columns cola and colb"];
  (enlist .Q.dd[cola;colb])!enlist ?[tab;enlist(=;.Q.pf;last .Q.PV);((cola;colb)!(cola;colb));(enlist `i)!enlist(count;`i)]
  }


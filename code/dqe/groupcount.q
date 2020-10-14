\d .dqe

groupcount:{[tab;cola;vara]
  .lg.o[`groupcount;"Counting amount of messages received with where clauses applied to columns column with variable vara"];
  (enlist vara)!enlist ?[tab;((=;.Q.pf;last .Q.PV);(=;column;enlist vara));1b;()]
  }

\d .dqe

groupcount:{[tab;cola;vara]
  .lg.o[`groupcount;"Counting amount of messages received with where clauses applied to columns cola and colb with variables vara and varb"];
  (enlist vara)!enlist ?[tab;((=;.Q.pf;last .Q.PV);(=;cola;enlist vara));1b;()]
  }

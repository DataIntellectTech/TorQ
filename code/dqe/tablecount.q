\d .dqe
tablecount:{[par]
  .lg.o[`test;"Getting table count dictionary"];
  .Q.pt!{[par;x]count ?[x;enlist(=;.Q.pf;par);0b;()]}[par]'[.Q.pt]                                              /- create dictionary of partition tables with their counts
  }

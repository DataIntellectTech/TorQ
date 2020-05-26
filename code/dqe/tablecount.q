\d .dqe
tablecount:{[par]
  .lg.o[`tablecount;"Getting table count dictionary"];
  /- create dictionary of partition tables with their counts
  .Q.pt!{[par;x]count ?[x;enlist(=;.Q.pf;par);0b;()]}[par]'[.Q.pt]
  }

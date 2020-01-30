.dqe.evaluate:{[table]
  if[count where (),(11h=abs type table) & (table in .Q.pt);                                                    /- checks if any variable for check function is type symbol
    .lg.o[`evaluate;(string table)," has been changed to a functional select with a where clause"];
    ?[table;enlist (=;.Q.pf;last .Q.PV);0b;()]]
  }

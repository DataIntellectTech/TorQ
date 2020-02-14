\d .dqe
symcount:{[t;colname]
  /count {?[x; enlist(=;.Q.pf;last .Q.PV); 1b; (enlist y)!(enlist y)]}[t;colname]
  (enlist t)!(enlist count {?[x; (); 1b; (enlist y)!(enlist y)]}[t;colname])
  }

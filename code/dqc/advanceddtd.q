\d .dqc

advanceddtd:{[tab;adfunc;advars:percentage]
  listt:{?[tab;((=;`funct;enlist adfunc);(=;`resultkeys;enlist advars);(=;.Q.pf;x));1b;()]}each (first -2#.Q.PV;(last .Q.PV));
  t:{value first select from listt[x]`resulttables where sym=adsyms}each (0;1);

/- this gets a list of boolean of whether all the counts within the resulttables is equal
  ((first listt[1]`resulttables) each exec sym from first listt[1]`resulttables)~' (first listt[0]`resulttables) each exec sym from first listt[0]`resulttables;



  (c;"The value of ",(string adsyms)," with by clauses applied to  ",(string advars),$[c:t[0]=t[1];" matched ";" did not match "]," in the days: ",(string last .Q.PV)," and ",string first -2#.Q.PV)
  }


\d .dqc

advanceddtd:{[tab;adfunc;advars;adsyms]
  listt:{?[tab;((=;`funct;enlist adfunc);(=;`resultkeys;enlist advars);(=;.Q.pf;x));1b;()]}each (first -2#.Q.PV;(last .Q.PV));
  t:{value first select from listt[x]`resulttables where sym=adsyms}each (0;1);
  (c;"The value of ",(string adsyms)," with by clauses applied to  ",(string advars),$[c:t[0]=t[1];" matched ";" did not match "]," in the days: ",(string last .Q.PV)," and ",string first -2#.Q.PV)
  }


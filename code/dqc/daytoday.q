\d .dqc

/- compares the value of a column in DQEDB from previous day to two days ago (assuming the column has one value per day)
daytoday:{[tab;cola;colb;vara;varb]
  listt:{?[tab;((=;cola;enlist vara);(=;colb;enlist varb);(=;.Q.pf;x));1b;()]}each (first -2#.Q.PV;(last .Q.PV));
  (c;"The value of ",(string vara)," and ",(string varb),$[c:(first listt[0]`resvalue)=first listt[1]`resvalue;" matched ";" did not match "]," in the days: ",(string last .Q.PV)," and ",string first -2#.Q.PV)
  }

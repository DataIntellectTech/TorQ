\d .dqc


advancedsymdtd:{[tab;func;vars]
  /- List containing the advancedres table of the function and parameter specified from yesterday and two days ago
  listt:{?[tab;((=;`funct;enlist func);(=;`resultkeys;enlist vars);(=;.Q.pf;x));1b;()]}each (first -2#.Q.PV;(last .Q.PV));
  /- List containing only the keys of the two tables from yesterday and two days ago
  keyst:{key first listt[x]`resulttables}each (0;1);
  /- if everything matches, then proceed to 1b on the result. if not, check what is missing from today/missing from yesterday
  $[1b=(keyst[0] in keyst[1]) and all keyst[0] in keyst[1];
    (1b;"All keys from day ",(string last .Q.PV)," matched ",string first -2#.Q.PV);
    /- mfy - missing from yesterday. mft - missing from two days ago
    (0b;"Error: ",$[count mfy;" ",(", " sv exec ((string sym),'" ",'ex) from mfy:keyst[0] where not keyst[0] in keyst[1])," missing from yesterday."],$[count mft;" ",(", " sv exec ((string sym),'" ",'ex) from mft:keyst[1] where not keyst[1] in keyst[0])," missing from two days ago."]] 
  }

advancedperdtd:{[]}

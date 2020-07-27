\d .dqc


advancedsymdtd:{[tab;func;vars]
  /- List containing the advancedres table of the function and parameter specified from yesterday and two days ago
  listt:{[tab;func;vars;dt]?[tab;((=;`funct;enlist func);(=;`resultkeys;enlist vars);(=;.Q.pf;dt));1b;()]}[tab;func;vars;]each -2#.Q.PV;
  /- List containing only the keys of the two tables from yesterday and two days ago
  keyst:{key first x`resulttables}each listt;
  /- if everything matches, then proceed to 1b on the result. if not, check what is missing from today/missing from yesterday
  $[1b=(all b in a)and all(a:keyst 0)in b:keyst 1;
    (1b;"All keys from day ",(string last .Q.PV)," matched keys from ",string first -2#.Q.PV);
    (0b;"Error: ",$[count mfy;(", "sv exec((string sym),'" ",'ex)from mfy:a where not a in b)," missing from yesterday."],$[count mft;" ",(", "sv exec((string sym),'" ",'ex)from mft:b where not b in a)," missing from two days ago."])
    ]
  }

advancedperdtd:{[tab;func;vars;percentage]
  /- List containing the advancedres table of the function and parameter
  /- specified from the last two days
  listt:{?[tab;((=;`funct;enlist func);(=;`resultkeys;enlist vars);(=;.Q.pf;x));1b;()]}each -2#.Q.PV;
  /- List containing only the advancedres tables from yesterday and two days ago
  advancedreslist:{first x`resulttables}each listt;
  /- changing the column name for the table two days ago
  advancedreslist[1]:((-1_cols advancedreslist[1]),`bycounttwo)xcol advancedreslist[1];
  advancedreslist[0]:((-1_cols advancedreslist[0]),`bycountone)xcol advancedreslist[0];
  /- Joining the two tables for comparision
  joinedadvancedres:advancedreslist[0]uj advancedreslist[1];
  /- Filing in zeros for both bycount columns
  joinedadvancedres:update bycountone:0^bycountone,bycounttwo:0^bycounttwo from joinedadvancedres;
  /- Getting the percentage difference from two days ago to today
  joinedadvancedres:update percentages:100*(abs bycountone-bycounttwo)%bycounttwo from joinedadvancedres;
  "The following sym, ex pairs have changed more than ",(string percentage),"%: ",exec(", "sv(string sym),'" ",'ex)from joinedadvancedres where percentages>percentage
  }

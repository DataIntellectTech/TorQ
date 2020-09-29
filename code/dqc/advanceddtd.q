\d .dqc

// This function checks if sym has changed from the past two partitions
// in tables of resultdata that are contained in the advancedres of dqe.

advancedsymdtd:{[tab;func;vars]
  /- List containing the advancedres table of the function and parameter specified from the previous two partitions
  listt:{[tab;func;vars;dt]?[tab;((=;`funct;enlist func);(=;`resultkeys;enlist vars);(=;.Q.pf;dt));1b;()]}[tab;func;vars;]each -1+(-2#.Q.PV);
  /- List containing only the keys of the two tables from yesterday and two days ago
  keyst:{key first x`resultdata}each listt;
  /- a utility function for the conditional
  f:{" "sv({x,'".",'y}/){$[10h=type x;x;string x]}each x` vs y};
  /- if everything matches, then proceed to 1b on the result. if not, check what is missing from today/missing from yesterday
  $[(all b in a)and all(a:keyst 0)in b:keyst 1;
    (1b;"All keys from day ",(string last .Q.PV)," matched keys from ",string first -2#.Q.PV);
    (0b;"Error: ",$[count mfy:a where not a in b;" ",f[mfy;vars]," missing from T-1.";""],$[count mft:b where not b in a;" ",f[mft;vars]," missing from T-2.";""])]
  }

// This function checks if count from tables of resultdata has changed
// and past a certain percentage from the past two partitions.

advancedperdtd:{[tab;func;vars;percentage]
  /- List containing the advancedres table of the function and parameter
  /- specified from the last two days
  listt:{[tab;func;vars;dt]?[tab;((=;`funct;enlist func);(=;`resultkeys;enlist vars);(=;.Q.pf;dt));1b;()]}[tab;func;vars;]each -1+(-2#.Q.PV);
  /- List containing only the advancedres tables from yesterday and two days ago
  advancedreslist:{first x`resultdata}each listt;
  /- changing the column name for the table two days ago
  advancedreslist[1]:((-1_cols advancedreslist[1]),`bycounttwo)xcol advancedreslist[1];
  advancedreslist[0]:((-1_cols advancedreslist[0]),`bycountone)xcol advancedreslist[0];
  /- Joining the two tables for comparision
  joinedadvancedres:advancedreslist[0]uj advancedreslist[1];
  /- Getting the percentage difference from two days ago to today
  joinedadvancedres:update percentages:100*(abs (0^bycountone)-(0^bycounttwo))%bycounttwo from joinedadvancedres;
  /- Create error message for the conditional below.
  errorsym:{" "sv({x,'".",'y}/){$[10h=type x;x;string x]}each x` vs y}[key select from joinedadvancedres where percentages>percentage;vars];
  $[not count errorsym;
    (1b;"No keys have exceeded more than ",(string percentage),"% from ",{x," to ",y}. string -2#.Q.PV);
    (0b;("The following keys ",ssr[string vars;".";", "]," have changed more than ",(string percentage),"%: ",errorsym))]
  }


// table tab (eg `advancedres), the function func we want to look at (eg
// `bycount), the vars we are querying (eg `sym) and the number of days n we
// want to look back at.

// For example, within the advancedres, there is a column resultdata that
// contains tables queried by functions, in this example, bycount.
// Example table from TorQ's sample data, hdb's quote table queried
//  by bycount under col `sym
/
sym | bycount
----| -------
AAPL| 524305
AIG | 526728
AMD | 526464
DELL| 526107
DOW | 526888
GOOG| 526224
HPQ | 527033
IBM | 527199
INTC| 525194
MSFT| 526112
\
// The medianfunc then return whehter the bycount data of T+1 is off
// by the percentage to the median of bycounts over T+n.
medianfunc:{[tab;func;vars;n;percentage]
  /- List containing T+1 to T+n
  listt:{[tab;func;vars;dt]?[tab;((=;`funct;enlist func);(=;`resultkeys;enlist vars);(=;.Q.pf;dt));1b;()]}[tab;func;vars;]each -1+(neg n)#.Q.PV;
  /- List containing only the advancedres tables from T+1 to T+n
  advancedreslist:{first x`resultdata}each listt;
  /- changing the column name for the tables in advancedreslist
  advancedreslist:{((-1_cols x[1]),.Q.dd[x[0];`$string x[2]])xcol x[1]}each flip(n#func;advancedreslist;til n);
  /- Joining the the tables from T+1 to T+n
  joinedadvancedres:(uj/)advancedreslist;
  joinedadvancedres:update medbycount:med (value joinedadvancedres)each cols value joinedadvancedres from joinedadvancedres;
  t:value joinedadvancedres;
  joinedadvancedres:update perchange:100*abs(t[`bycount.0]-t[`medbycount])%t[`bycount.0] from joinedadvancedres;
  $[all c:percentage>(value joinedadvancedres)[`perchange];
    (1b;"Numbers today from the bycount did not exceed the provided percentage:",(string percentage),"%");
    (0b;"The following syms counts increased exceeded the given percentage compared to the median: ",(", "sv string ((flip 0!joinedadvancedres)`sym) [where not c])," by ",(", "sv string ((flip 0!joinedadvancedres)`perchange)[ where not c]),"percent, respectively")]
  }

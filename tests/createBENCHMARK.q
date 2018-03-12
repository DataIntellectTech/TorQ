-1"CREATING BENCHMARKS...";
def: .Q.def[`stackID`user`pass`testCSV`benchM!(1680;`admin;`admin;`:UnitTesting/tests.csv;`:UnitTesting/benchM/)].Q.opt[.z.x];

h:hopen `$"::",string[def[`stackID]],":admin:admin";

quoteBENCHMARK:100#h(".eod.queryq[first exec w from .servers.SERVERS where procname=`hdb1;.z.d-2]");
tradeBENCHMARK:h(".eod.queryt[first exec w from .servers.SERVERS where procname=`hdb1;.z.d-2]");
tablerBENCHMARK:h(".eod.tabler[first exec w from .servers.SERVERS where procname=`hdb1;.z.d-2]");

save hsym`$string[def[`benchM]],"quoteBENCHMARK.csv"
save hsym`$string[def[`benchM]],"tradeBENCHMARK.csv"
save hsym`$string[def[`benchM]],"tablerBENCHMARK.csv"

-1"BENCHMARKS CREATED FOR ",string[.z.d-2];-1"PLEASE MODIFY DATES IN ",string[def[`testCSV]]," AND RESTART UNIT TESTS!";

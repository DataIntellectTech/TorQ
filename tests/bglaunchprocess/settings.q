/variables and fns to be used during the unit tests:
/let the test port_no be 7124

input1:`procname`proctype`U`localtime`p`T`g`w`qcmd`custom`load!("test2";"test";"${TORQHOME}/tests/bglaunchprocess/accesslist.csv";"0";string 3+"J"$getenv`KDBBASEPORT;"180";"1";"1000";"q";"custom_arg";"${TORQHOME}/tests/bglaunchprocess/settings.q");
input2:`procname`proctype`load`U!("test3";"test";"${TORQHOME}/tests/bglaunchprocess/settings.q"; "${TORQHOME}/tests/bglaunchprocess/accesslist.csv");
.servers.DISCOVERY:(),`$"::",string 1+ "J"$getenv`KDBBASEPORT;
.servers.startup[];


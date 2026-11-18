/variables and fns to be used during the unit tests:
/let the test port_no be 7124

input1:`procname`proctype`U`localtime`p`T`g`w`qcmd`custom`load!("test2";"test";"${KDBAPPCONFIG}/passwords/accesslist.txt";"0";"7124";"180";"1";"1000";"q";"custom_arg";"${TORQHOME}/tests/bglaunchprocess/settings.q");
input2:`procname`proctype`load!("test3";"test";"${TORQHOME}/tests/bglaunchprocess/settings.q");
.servers.startup[];

/the messages .sys.bglaunch and .sys.bgkill log, kept through TorQ's logging hook (.lg.ext) for the suite to check
bglogged:();
.lg.ext:{[loglevel;proctype;proc;id;message;dict] if[id in `launchprocess`killprocess; bglogged,::enlist message]};

/the process launched with input2 listens on a port of its own choosing (-p 0W), and the suite finds it in discovery.
/Under a connection limit, such as KDB-X's free licence, TorQ turns discovery off and takes connection details from a
/file instead (DISCOVERYCONNECT in config/settings/default.q). Then each process of the suite writes its port to a file
/in KDBLOG when it starts, and the suite finds the process there. run.sh removes the files
portfile:{hsym`$getenv[`KDBLOG],"/bglaunchprocess_",string[x],".port"};
if[(not .servers.DISCOVERYCONNECT) and 0<system"p"; portfile[.proc.procname] 0: enlist string system"p"];

/the address of a process of the suite, from discovery or, with discovery off, from its port file; null until it is there
findproc:{[pname] $[.servers.DISCOVERYCONNECT;
  @[{first exec hpup from .servers.querydiscovery[`test] where procname=x};pname;`];
  $[()~key portfile pname;`;`$"::",first read0 portfile pname]]};

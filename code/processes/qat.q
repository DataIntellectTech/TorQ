/TorQ QA Testing Process

// read in connection details and set all processes as connections
procstab:.proc.readprocs .proc.file
expectedprocs:(exec procname from procstab) except `killtick`tpreplay1`qat1
.servers.CONNECTIONS:(exec distinct proctype from procstab) except `qat`kill`tickerlogreplay

/
  Standalone script for creating tests
  Usage:
  Add a test
  .tst.Add `name`description`connections`check`resultchecker!(
      `example_test;
      "Check that 1b equals 1b!";
      {};
      {1b};
      {x~1b}
   );
  Run all tests
    .tst.RunAll[]
  Run specific test
    .tst.RunCase `example_test
  Add connection details (can be included in the setup function)
    .tst.AddConn[`example_test;`rdb;`::1337]
  Opens connection before test execution, adds handle to global dictionary
    Conn[`rdb] "query"
  Modify function below to output results favourite format.
    .tst.SaveResults
\

\d .tst

// Contains test cases
// name - unique name for each test
// description - more info on what the test does
// connections - list of connections to make for the test
// check - actual test logic
Cases:([name:`symbol$()] description:();connections:();check:();args:();category:`$())

// run prior to testing to show if tests were up for each test
procstatus:{
  t:system getenv[`TORQHOME],"/torq.sh summary";
  d:(!). flip `$trim each ("|" vs' 1_t)[;1 2],enlist ("";"up");
  (enlist each x)!(enlist each d x)}

// active connections to be used during each test e.g. Conn[`rdb] "query"
Conn:(`$())!`int$();

// test logging functions
u.Log:{-1 x;}
u.LogCase:{[name;msg] -1 string[name]," : ",msg;}
u.LogCaseErr:{[name;msg] -2 string[name]," : ",msg;}

// input checking
casesTypes:`name`description`connections`check`args`category!(-11h;10h;-11 11h;100h;"h"$neg[19]+til 121;-11h)

inputDictCheck:{[dict]
  if[not all key[dict] in key casesTypes;'"missing param keys : ",-3!key[dict] where not key[dict] in key casesTypes];
  // format input dictionary
  dict:key[casesTypes]#dict;
  // check for incorrect types in test
  if[not all (type each dict) in' casesTypes;
    '"given incorrect types for these keys : \n",.Q.s `expected`got!(where not (type each dict) in' casesTypes)#/:(casesTypes;type each dict)
  ];
  // check that no test with this name already exists
  if[count select from Cases where name=dict`name;
    '"test with that name already exists : \n",(.Q.s select from Cases where name=dict`name),"\nTo proceed, remove using Remove ",-3!dict`name
  ];
  dict
  }

// add a test to Cases dictionary
Add:{[dict]
  dict:inputDictCheck dict;
  u.Log "Adding test : ",string dict`name;
  .tst.Cases:.tst.Cases upsert dict;
  }

// remove specific test from Cases dictionary
Remove:{[Name] .tst.Cases:delete from Cases where name=Name}

// run specific test in Cases dictionary
RunCase:{[Name]
  res:RunCaseInner Name;
  closeConn Name;
  $[res;
     u.LogCase[Name;"Test passed"];
     u.LogCaseErr[Name;"Test failed"]   
  ];
  res
 }

RunCaseInner:{[Name]
  if[not count case:0!select from .tst.Cases where name=Name;'"case does not exist : ",-3!Name];
  case:first case;
  if[not `~case`connections;  
    u.LogCase[Name;"Setting up necessary connections"];
    // AddConn[Name;]each case`connections;
    openConn Name;
  ];
  u.LogCase[Name;"Running test"];
  res:$[1<count value[case`check] 1; .; @][case`check;value case`args;{[n;err]u.LogCaseErr[n;err];0b}[Name]];
  res
 }

// run all tests in Cases dictionary
RunAll:{
  if[0=count .tst.Cases;'"no cases to run";:()];
  constat:procstatus exec connections from .tst.Cases;
  tests:update status:first'[constat'[connections]] from .tst.Cases;
  res:0!update result:@[.tst.RunCase;;0b] each name from tests where status=`up;
  SaveResults[res];
  res
 }

// output to json, can then save to directory for input into reporting tool
SaveResults:{[res]
  cat:exec distinct category from res;
  tblcat:{[res;cat]?[res;enlist (=;`category;enlist cat);0b;()]}[res]each cat;
  SaveResultsInner'[tblcat]}

// formats json report
SaveResultsInner:{[res]
  start:-6_-3!`long$.z.p;
  system"sleep 1";
  stop:-6_-3!`long$.z.p;
  steps:select name,status:{$[x;`passed;`failed]}each result from res;
  steps:update stage:`finished,steps:(),attachments:(),parameters:(),start:enlist start,stop:enlist stop from steps;
  name:string exec first category from res;
  uuid:-3!-1?0Ng;
  historyId:raze string 32#.Q.sha1 .j.j res;
  labels:([]name:("package";"testClass";"testMethod";"parentSuite";"host";"language");
  ace15282cc7a7737e7e1b76143250e2:("run all tests";"kdb QA testing";"QAT process";"test suite";first system"hostname";"q"));
  status:{[steps] t:`passed=(exec distinct status from steps);
          $[1=min t;"passed";0=max t;"failed";"broken"]}steps;
  d:`name`status`steps`start`stop`uuid`historyId`labels!
    (name;status;steps;start;stop;uuid;historyId;labels);
  json:ssr[.j.j d;"ace15282cc7a7737e7e1b76143250e2";"value"];
  f:`$":",getenv[`TORQHOME],"/testreports/",(1_uuid),"-result.json";
  h:hopen f;
  neg[h] json
  }

// manage ipc connections
// setup ipc connections e.g. start of each test
openConn:{[Name]
 `.tst.Conn set .tst.Conn upsert exec procname!w from .servers.getservers[`procname;.tst.testConn Name;()!();1b;1b];
 }

// connections required for test Name 
testConn:{[Name]
 exec connections from .tst.Cases where name=Name
 }

// close ipc connections e.g. end of each test
closeConn:{[Name]
  .servers.SERVERS:update w:{@[hclose;x;];0Ni} each w from .servers.SERVERS where procname in .tst.testConn[Name];
  @[`.tst;`Conn;0#];
 }

// function to load tests from a csv
loadtests:{[file]
  // extract tests from csv
  newtests:update category:`$first "."vs last "/"vs string file, {@[x;where (::)~'x;:;`]}value each connections, value each check from ("S****";enlist"|")0: file;
  // add these test to the Cases dictionary
  .tst.Add each newtests;
  }

\d .

// test whether a process is up
connectiontest:{all {1~x"1"}'[.tst.Conn]}

// inner function to test whether a construct exists on a process
constructcheckinner:{[construct;chktype;contype]
  chkfunct:{system x," ",string $[null y;`;y]};
  dict:`table`variable`view`function!chkfunct@/:"avbf";
  res:last[`$c] in dict[chktype][`$"."sv -1_c:"."vs string construct];
  $[null contype; res; min (res; contype=type value construct)]
  }

// outer function sends constructcheckinner query to the process
constructcheck:{[construct;chktype;contype]
  first[.tst.Conn](constructcheckinner;construct;chktype;contype)
  }

// test whether a process has all required subscriptions
subtest:{min count each first[.tst.Conn]({exec w from .servers.getservers[`procname;x;()!();0b;1b]}';(::;enlist)[0>type x]x)}

// test to check result of function called on its arguments
functest:{[func;args]
  numargsapply:first[.tst.Conn]({$[1<count x 1; .; @]};func);
  query:"eval[",string[func],"] ",string[numargsapply]," eval each ",.Q.s1 args;
  first[.tst.Conn]query 
  }

// come back to this - might need to add failcomment column
schemacheck:{[tab;colname;types;forkeys;attribute]
  origschema:0!meta tab;
  checkschema:([]c:colname;t:types;f:forkeys;a:attribute);
  all checkschema~'origschema
  }

// all test file paths
alltests:alltests where not max (alltests:{` sv/:x,/:key x} hsym`$getenv[`KDBTESTS],"/qat") like/: ("*.swp*";"*.swo*")

// load in test csv's
.tst.loadtests'[alltests];

// start connections
.servers.startup[]

.timer.repeat[17:00+.z.d;0W;1D00:00:00;(`.tst.RunAll;`);"Run tests at end of day"]

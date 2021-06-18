/TorQ QA Testing Process

// load in correct table schemas to test against
schemas:(!) . (@'[;1];meta each eval each last each)@\: parse each read0 hsym `$getenv[`TORQHOME],"/database.q"

// dictionary of connection details for processes from /appconfig/process.csv, e.g. .conn.procconns`discovery1 gives `:localhost:33501:discovery:pass 
.conn.procconns:(!) . (@[;2];{hsym `$x[0],'":",/:x[1],'":",/:{first $[null x;"";read0 x]}each hsym`$.rmvr.removeenvvar each last x})@\: @[;1;string value each .rmvr.removeenvvar']1_'("** S*";",")0:hsym `$getenv[`TORQAPPHOME],"/appconfig/process.csv"

// getting connection details via discovery
// {h:.conn.procconns `discovery1; `.servers.SERVERS set h".servers.SERVERS"}[]

// function to test the schemas of a process
testschemas:{[proc]
  // return list (1b;`$()) if test is passed, (0b;SYMBOL LIST OF FAILED TABS) if test is failed
  ({0=count x};::)@\:
    // open handle to process
    {h:hopen x;
      // retrieve list of tables to be compared against schemas  
      proctabs:(h"tables[]") inter key schemas; 
      // get the metas of these tables from the process
      tabmetas:h((first each)each meta each value each;first each proctabs);
      // test if these metas match the metas in schemas 
      proctabs where not tabmetas~'(first each)each schemas proctabs
    }[.conn.procconns proc]
  }

// function to load tests from a csv
loadtests:{[file]
  // extract tests from csv
  newtests:update {@[x;where (::)~'x;:;`]}value each connections, value each check, {$[(::)~x;`$();x]}each value each args from ("S****";enlist"|")0: file;
  // add these test to the Cases dictionary
  .tst.Add each newtests;
  }

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
Cases:([name:`symbol$()] description:();connections:();check:();args:())

// create empty dictionary for connection handles
.conn.h:(`$())!`int$();

procstatus:{
  t:system getenv[`TORQHOME],"/torq.sh summary";
  d:(!). flip `$trim each ("|" vs' 1_t)[;1 2],enlist ("";"up");
  (enlist each x)!(enlist each d x)}

// connections that are required during each test run
Conns:([name:`symbol$();proc:`symbol$()] hp:`symbol$();h:`int$())
// active connections to be used during each test e.g. Conn[`rdb] "query"
Conn:(`$())!`int$();

// test logging functions
u.Log:{-1 x;}
u.LogCase:{[name;msg] -1 string[name]," : ",msg;}
u.LogCaseErr:{[name;msg] -2 string[name]," : ",msg;}

// input checking
casesTypes:`name`description`connections`check`args!(-11h;10h;-11 11h;100h;"h"$neg[19]+til 121)

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
  .tst.Cases:Cases upsert dict;
  }

// remove specific test from Cases dictionary
Remove:{[Name] .tst.Cases:delete from Cases where name=Name}

// run specific test in Cases dictionary
RunCase:{[Name]
  res:RunCaseInner Name;
  closeConn Name;
  res
 }

RunCaseInner:{[Name]
  if[not count case:0!select from .tst.Cases where name=Name;'"case does not exist : ",-3!Name];
  case:first case;
  if[not `~case`connections;  
    u.LogCase[Name;"Setting up necessary connections"];
    AddConn[Name;]each case`connections;
    openConn Name;
  ];
  u.LogCase[Name;"Running test"];
  res:$[1<count value[case`check] 1; .; @][case`check;case`args;{[n;err].u.LogCaseErr[n;err];0b}[Name]];
  res
 }

// run all tests in Cases dictionary
RunAll:{
  if[0=count .tst.Cases;'"no cases to run";:()];
  constat:procstatus exec connections from .tst.Cases;
  tests:update status:first'[constat'[connections]] from .tst.Cases;
  res:0!update result:@[.tst.RunCase;;0b] each name from tests where status=`up;
  SaveResults res;
  res
 }

// output to json, can then save to directory for input into reporting tool
SaveResults:{[results]
  results:.h.xd select name,description,(","sv' "`",/:'string args),string result from results;
  f:`$":",getenv[`TORQHOME],"/testreports/testResults_",(-10_{ssr[x;y;"_"]}/[string .z.p;"D.:"]),".xml";
  h:hopen f;
  neg[h] results
 }


// manage ipc connections
// setup ipc connections e.g. start of each test
openConn:{[Name]
  update h:hopen each hp from .tst.Conns where name=Name;
  `Conn upsert exec proc!h from .tst.Conns where name=Name;
 }

// close ipc connections e.g. end of each test
closeConn:{[Name]
  update h:{hclose x;0Ni} each h from .tst.Conns where name=Name;
  @[`.tst;`Conn;0#];
 }

// add host and port under each test
// e.g. .tst.AddConn[`schemacheck_1;`rdb;`::1337]
AddConn:{[Name;procName]
  `Conns upsert (Name;procName;.conn.procconns[procName];0Ni);
 }

\d .

.timer.repeat[17:00+.z.d;0W;1D00:00:00;(`.tst.RunAll;`);"Run tests at end of day"]

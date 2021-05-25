// load in correct table schemas to test against
schemas:(!) . (@'[;1];meta each eval each last each)@\: parse each read0 hsym `$getenv[`TORQHOME],"/database.q"

// function to get values of environment variables from strings, e.g. removeenvvar"{KDBBASEPORT}+1" produces "6000+1"
removeenvvar:{
        // positions of {}
        pos:ss[x]each"{}";
        // check the formatting is ok
        $[0=count first pos; :x;
        1<count distinct count each pos; '"environment variable contains unmatched brackets: ",x;
        (any pos[0]>pos[1]) or any pos[0]<prev pos[1]; '"failed to match environment variable brackets on supplied string: ",x;
        ()];

        // cut out each environment variable, and retrieve the meaning
        raze {$["{"=first x;getenv`$1 _ -1 _ x;x]}each (raze flip 0 1+pos) cut x}

// dictionary of connection details for processes from /appconfig/process.csv, e.g. procconns`discovery1 gives `:localhost:33501:discovery:pass 
procconns:(!) . (@[;2];{hsym `$x[0],'":",/:x[1],'":",/:{first $[null x;"";read0 x]}each hsym`$removeenvvar each last x})@\: @[;1;string value each removeenvvar']1_'("** S*";",")0:hsym `$getenv[`TORQAPPHOME],"/appconfig/process.csv"

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
    }[procconns proc]
  }

loadtests:{[file]
  // extract tests from csv
  newtests:update value each setup, value each check, value each resultchecker from ("S****";enlist"|")0: file;
  // add these test to the Cases dictionary
  .tst.Add each newtests
  }



/
  TODO
  add exit or continue on fail? Group tests?
  add each step in RunCase to a log
\

/
  Standalone script for creating tests
  Usage:
  Add a test
  .tst.Add `name`description`setup`check`resultchecker!(
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

// Contains test cases
// name - unique name for each test
// description - more info on what the test does
// setup - pre check setup
// check - actual test logic
// resultchecker - given the results from check, determine what to do with it
Cases:([name:`symbol$()] description:();setup:();check:();resultchecker:())

// create empty dictionary for connection handles
.conn.h:(`$())!`int$();

/ connections that are required during each test run
Conns:([name:`symbol$();proc:`symbol$()] hp:`symbol$();h:`int$())
/ active connections to be used during each test e.g. Conn[`rdb] "query"
Conn:(`$())!`int$();

\d .tst

// Roll own logging funcs
u.Log:{-1 x;}
u.LogCase:{[name;msg] -1 string[name]," : ",msg;}
u.LogCaseErr:{[name;msg] -2 string[name]," : ",msg;}

// input checking
casesTypes:`name`description`setup`check`resultchecker!-11 10 100 100 100h
inputDictCheck:{[dict]
  if[not all key[dict] in key casesTypes;'"missing param keys : ",-3!key[dict] where not key[dict] in key casesTypes];
  // format input dictionary
  dict:key[casesTypes]#dict;
  if[not all casesTypes~'type each dict;'"given incorrect types for these keys : \n",.Q.s `expected`got!(where not casesTypes~'type each dict)#/:(casesTypes;type each dict)];
  if[count select from `Cases where name=dict`name;'"test with that name already exists : \n",(.Q.s select from `Cases where name=dict`name),"\nTo proceed, remove using .tst.Remove ",-3!dict`name];
  dict
  }

Add:{[dict]
  dict:inputDictCheck dict;
  u.Log "Adding test : ",string dict`name;
  `Cases upsert dict;
  }

Remove:{[Name] delete from `Cases where name=Name}

RunCase:{[Name]
  openConn Name;
  res:RunCaseInner Name;
  closeConn Name;
  res
 }

RunCaseInner:{[Name]
  if[not count case:0!select from `Cases where name=Name;'"case does not exist : ",-3!Name];
  case:first case;
  u.LogCase[Name;"Running setup function"];
  res:@[case`setup;(::);{[n;err].tst.u.LogCaseErr[n;err];0b}[Name]];
  if[res~0b;u.LogCase[Name;"test exiting"];:0b];
  u.LogCase[Name;"Running check function"];
  res:@[case`check;(::);{[n;err].tst.u.LogCaseErr[n;err];0b}[Name]];
  if[res~0b;u.LogCase[Name;"test exiting"];:0b];
  u.LogCase[Name;"Running resultchecker function against result"];
  @[case`resultchecker;res;{[n;err].tst.u.LogCaseErr[n;err];0b}[Name]]
 }

RunAll:{
  if[0=count `. `Cases;'"no cases to run";:()];
  res:0!update result:@[.tst.RunCase;;{"Failed : ",x;0b}] each name from `. `Cases;
  SaveResults res;
  res
 }

// output to json, can then save to directory for input into reporting tool
SaveResults:{[results]
  results:select name,result from results;
  r:.j.j `status`total`failed`cases!(`fail`pass all results`result;count results;sum not results`result;results);
  f:`$"testResults_",-10_{ssr[x;y;"_"]}/[string .z.p;"D.:"];
  set[f;r];
  save `$getenv[`TORQHOME],"/testreports/",(string f),".json"
 }


// manage ipc connections
// setup ipc connections e.g. start of each test
openConn:{[Name]
  update h:hopen each hp from `Conns where name=Name;
  `Conn upsert exec proc!h from `Conns where name=Name;
 }

// tear down ipc connections e.g. end of each test
closeConn:{[Name]
  update h:{hclose x;0Ni} each h from `Conns where name=Name;
  @[`.;`Conn;0#];
 }

// add host and port under each test
// e.g. .tst.AddConn[`schemacheck_1;`rdb;`::1337]
AddConn:{[Name;procName;hp]
  `Conns upsert (Name;procName;hp;0Ni);
 }

\d .

// TODO remove
pass:`name`description`setup`check`resultchecker!(`test1;"testing cxtn";{x};{x};{x~x})
fail:`name`description`setup`check`resultchecker!(`test1;"testing cxtn";{x};{x};`funcname)

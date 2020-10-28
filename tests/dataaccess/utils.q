testfolder:hsym`$getenv[`KDBTESTS],"/dataaccess";
checkinputsfolder:hsym`$getenv[`KDBTESTS],"/dataaccess/checkinputs";

//- read dictionary of params from csv named according to the test {testname}.csv
gettestparams:{[test]exec parameter!get each parametervalue from .dataaccess.readcsv[`$string[checkinputsfolder],"/",string[test],".csv";"s*"]};

//- code to pass in a test name
//- extract the input parameter from {testname}.csv
//- extract the expected error from checkinputerrors.csv
//- compare error with expected error
checkreturnederror:{[test]errors[test;`error]~@[.checkinputs.checkinputs;gettestparams test;::]};
checkreturnederrorcustom:{[test;param]errors[test;`error]~@[.checkinputs.checkinputs;param;::]};

\d .proc
getconfigtest:getconfigfile;

//- if we can find the config file in test folder - use it
//- otherwise take it from original path
getconfigfile:{[path]
  base:getenv`KDBCONFIG;
  configbase:getconfigtest path;
  setenv[`KDBCONFIG;getenv[`TORQHOME],"/tests/dataaccess/config"];
  configtest:getconfigtest path;
  setenv[`KDBCONFIG;base];
  if[any configpathexists'[configtest];:configtest];
  :configbase;
 };

configpathexists:{[path]not()~key hsym path};

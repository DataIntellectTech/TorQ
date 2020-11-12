testpath:hsym`$getenv[`KDBTESTS],"/dataaccess/checkquery";
processcsv:` sv testpath,`config`process.csv;

//- code to pass in a test name
//- extract the input parameter from {testname}.csv
//- extract the expected error from checkerrors.csv
//- compare error with expected error
checkreturnederror:{[test]errors[test;`error]~@[.checkinputs.checkinputs;gettestparams test;::]};
checkreturnederrorcustom:{[test;param]errors[test;`error]~@[.checkinputs.checkinputs;param;::]};
checkqueryparams:{[test].eqp.extractqueryparams[gettestparams test;.eqp.queryparams]};

//- read dictionary of params from csv named according to the test {testname}.csv
gettestparams:{[test]exec parameter!get each parametervalue from .dataaccess.readcsv[` sv testpath,`testdata,`$string[test],".csv";"s*"]};

testpath:hsym`$getenv[`KDBTESTS],"/dataaccess/reconnection";
processcsv:` sv testpath,`config`process.csv;

//- code to pass in a test name
//- extract the input parameter from {testname}.csv
//- extract the expected error from checkinputerrors.csv
//- compare error with expected error
checkreturnederror:{[test]errors[test;`error]~@[getdata;gettestparams test;::]};
checkreturnederrorcustom:{[test;param]errors[test;`error]~@[getdata;param;::]};

//- read dictionary of params from csv named according to the test {testname}.csv
gettestparams:{[test]exec parameter!get each parametervalue from .dataaccess.readcsv[` sv testpath,`testdata,`$string[test],".csv";"s*"]};

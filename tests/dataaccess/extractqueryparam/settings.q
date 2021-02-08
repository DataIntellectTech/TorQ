inputpath:hsym`$getenv[`KDBTESTS],"/dataaccess/extractqueryparam/input";
outputpath:hsym`$getenv[`KDBTESTS],"/dataaccess/extractqueryparam/output";
processcsv:hsym`$getenv[`KDBTESTS],"/dataaccess/extractqueryparam/`config`process.csv";

//- code to pass in a test name
//- extract data from the input and output directories
//- compare function output with expected output

getinputparams:{[test]exec parameter!get each parametervalue from .checkinputs.readcsv[` sv inputpath,`$string[test],".csv";"s*"]};

getoutputparams:{[test]exec parameter!get each parametervalue from .checkinputs.readcsv[` sv outputpath,`$string[test],".csv";"s*"]};

testfunction:{[test] getoutputparams[test]~.eqp.extractqueryparams[getinputparams[test];.eqp.queryparams]};

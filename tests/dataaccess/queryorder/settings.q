inputpath:hsym`$getenv[`KDBTESTS],"/dataaccess/queryorder/inputs";
outputpath:hsym`$getenv[`KDBTESTS],"/dataaccess/queryorder/outputs";
processcsv:hsym`$getenv[`KDBTESTS],"/dataaccess/queryorder/`config`process.csv";

//- code to pass in a test name
//- extract the input dictionary from {testname}.csv
//- extract the respone from .queryorder.orderquery
//- compare output with expected one


getinputparams:{[test]exec parameter!get each parametervalue from .dataaccess.readcsv[` sv inputpath,`$string[test],".csv";"s*"]};

getoutputparams:{[test]T:exec parameter!get each parametervalue from .dataaccess.readcsv[` sv outputpath,`$string[test],".csv";"i*"];:(T[til 4])};


testfunction:{[testquery] getoutputparams[`$testquery]~.queryorder.orderquery[getinputparams[`$testquery]][1+til 4]};




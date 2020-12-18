inputpath:hsym`$getenv[`KDBTESTS],"/dataaccess/extractqueryparam/input";
outputpath:hsym`$getenv[`KDBTESTS],"/dataaccess/extractqueryparam/output";
processcsv:hsym`$getenv[`KDBTESTS],"/dataaccess/extractqueryparam/`config`process.csv";

//- code to pass in a test name
//- extract data from the input and output directories
//- compare function output with expected output

getinputparams:{[test]get ` sv (inputpath;`$string[test])};

getoutputparams:{[test]get ` sv (outputpath;`$string[test])};


testfunction:{[testquery] getoutputparams[`$testquery]~.eqp.extractqueryparams[getinputparams[`$testquery];.eqp.queryparams]};

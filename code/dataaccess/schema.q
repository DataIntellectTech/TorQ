\d .schema

// define the tickerplant to cross check for default timecolumn
tickerplant:`stp1
// define allowed operators and operators which can be used with a not statement for filter and freeformwhere parameter
allowedops:(<;>;<>;in;within;like;<=;>=;=;~;not);
allowednot:(within;like;in);
// functions that can be queried under aggregations, these functions support 'map reduce'
validfuncs:`avg`cor`count`cov`dev`distinct`first`last`max`med`min`prd`sum`sumsq`var`wavg`wsum;
// functions which return a single value for aggregations
returnone:`first`last`avg`count`dev`max`med`min`prd`sum`var`wavg`wsum;
// functions with two inputs required for aggregations
dvalidfuncs:`cor`cov`wavg`wsum;
// allowed functions and numerals for freeform queries
validfreeformfuncs:`avg`cor`count`cov`dev`distinct`first`last`max`med`min`prd`sum`var`wavg`wsum`0`1`2`3`4`5`6`7`8`9`;
// dictionary used to define timescale for time bucket intervals
timebarmap:`nanosecond`timespan`microsecond`second`minute`hour`day!1 1 1000 1000000000 60000000000 3600000000000 86400000000000;
// load in error messages for checkinputs
errors:1!.checkinputs.readcsv[hsym`$getenv[`KDBCONFIG],"/dataaccess/errormessages.csv";"s*"]
//load in examples for checkinputs
examples:1!.checkinputs.readcsv[hsym`$getenv[`KDBCONFIG],"/dataaccess/examples.csv";"s*"]

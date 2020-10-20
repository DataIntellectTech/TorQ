// Set up results and logging directories
.k4.setup:{[respath;testname]
  if[not 11h=type key hsym `$respath;system "mkdir -p ",respath];
  if[not 11h=type key hsym `$logpath:raze respath,"/logs/";system "mkdir ",logpath];
  .proc.createlog[logpath;testname;`$ssr[string .z.p;"[D.:]";"_"];0b];
  };

// Write test results to disk
.k4.writeres:{[res;err;respath;rtime;testname]
  // Generate file names and create them if they don't exist
  resfile:"results_",(raze "." vs string .z.d),".csv";
  errfile:"failures_",(raze "." vs string .z.d),".csv";
  if[not 11h=type key hsym `$respath;system "mkdir -p ",respath];
  if[not -11h=type key hsym `$rf:respath,"/",resfile;system "touch ",rf;.lg.o[testname;"Creating file ",rf]];
  if[not -11h=type key hsym `$ef:respath,"/",errfile;system "touch ",ef;.lg.o[testname;"Creating file ",ef]];

  // Timestamp tests
  res:`runtime xcols update runtime:first rtime from delete timestamp from res;
  err:`runtime xcols update runtime:first rtime from delete timestamp from err;

  // Write test results and errors to these files
  .lg.o[testname;"Writing ",string[count KUTR]," results rows and ",string[count KUerr]," error rows"];
  hclose abs neg[hopen hsym `$rf] $[hcount hsym `$rf;1;0]_csv 0: res;
  hclose abs neg[hopen hsym `$ef] $[hcount hsym `$ef;1;0]_csv 0: err;
  };

//-- SCRIPT START --//

// Grab relevant command-line arguments
clargs:({x,string[.z.d],"/"};{"P"$x};{`$last "/" vs x}) @' first each (.Q.opt .z.x)[`testresults`runtime`test];

// Set up results and logging directories if not in debug mode and results directory defined
if[01b~`debug`testresults in key .Q.opt .z.x;.[.k4.setup;clargs 0 2;{.lg.e[`test;"Error: ",x]}]];

// Load & run tests, show results
KUltd each hsym`$.proc.params[`test];
KUrt[];
show each ("k4unit Test Results";KUTR;"k4unit Test Errors";KUerr);

// If enabled write results to disk
if[all `write`testresults in key .Q.opt .z.x;.[.k4.writeres;(KUTR;KUerr),clargs;{.lg.e[`test;"Error: ",x]}]];
if[not `debug in key .Q.opt .z.x;exit 0];
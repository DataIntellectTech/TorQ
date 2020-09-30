// Write test results to disk
.k4.writeres:{[res;err;respath;rtime;testname]
  // Generate file names anc create them if they don't exist
  resfile:"results_",(raze "." vs string .z.d),".csv";
  errfile:"errors_",(raze "." vs string .z.d),".csv";
  if[not 11h=type key hsym `$respath;system "mkdir ",respath;.lg.o[testname;"Creating folder ",respath]];
  if[not -11h=type key hsym `$rf:respath,"/",resfile;system "touch ",rf;.lg.o[testname;"Creating file ",rf]];
  if[not -11h=type key hsym `$ef:respath,"/",errfile;system "touch ",ef;.lg.o[testname;"Creating file ",ef]];

  // Timestamp tests
  res:`runtime xcols update runtime:first rtime from delete time from res;
  err:`runtime xcols update runtime:first rtime from delete time from err;

  // Write test results and errors to these files
  .lg.o[testname;"Writing ",string[count KUTR]," results rows and ",string[count KUerr]," error rows"];
  hclose abs neg[hopen hsym `$rf] $[hcount hsym `$rf;1;0]_csv 0: res;
  hclose abs neg[hopen hsym `$ef] $[hcount hsym `$ef;1;0]_csv 0: err;
  };

KUltd each hsym`$.proc.params[`test];

KUrt[];

show "k4unit Test Results"
show KUTR
show "k4unit Test Errors"
show KUerr

// If enabled and if this is a TorQ process, write results to disk
if[.k4.savetodisk & (last "/" vs .z.X 1) like "torq*";
  args:(KUTR;KUerr),({x};{"P"$x};{`$last "/" vs x}) @' first each (.Q.opt .z.x)[`results`runtime`test];
  .[.k4.writeres;args;{.lg.o[testname;"Error: ",x]}];
  exit 0
  ];
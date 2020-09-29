// Write test results to disk
.k4.writeres:{[res;err;respath;rtime]
  // Generate file names anc create them if they don't exist
  resfile:"results_",(raze "." vs string .z.d),".csv";
  errfile:"errors_",(raze "." vs string .z.d),".csv";
  if[not 11h=type key hsym `$respath;system "mkdir ",respath;show "Creating folder ",respath];
  if[not -11h=type key hsym `$rf:respath,"/",resfile;system "touch ",rf;show "Creating file ",rf];
  if[not -11h=type key hsym `$ef:respath,"/",errfile;system "touch ",ef;show "Creating file ",ef];

  // Timestamp tests
  res:`runtime xcols update runtime:first rtime from res;
  err:`runtime xcols update runtime:first rtime from err;

  // Write test results and errors to these files
  show "Writing ",string[count KUTR]," results rows and ",string[count KUerr]," error rows";
  hclose abs neg[hopen hsym `$rf] $[hcount hsym `$rf;1;0]_csv 0: res;
  hclose abs neg[hopen hsym `$ef] $[hcount hsym `$ef;1;0]_csv 0: err;
  };

KUltd each hsym`$.proc.params[`test];

KUrt[];

show "k4unit Test Results"
show KUTR
show "k4unit Test Errors"
show KUerr

// If enabled, write results to disk
if[.k4.savetodisk;
  .[.k4.writeres;(KUTR;KUerr;first (.Q.opt .z.x)[`results];"P"$first (.Q.opt .z.x)[`runtime]);{show "Error: ",x}];
  exit 0
  ];
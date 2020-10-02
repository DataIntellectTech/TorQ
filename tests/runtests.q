// Set up results and logging directories
.k4.setup:{[respath;testname]
  if[not 11h=type key hsym `$respath;system "mkdir -p ",respath];
  if[not 11h=type key hsym `$logpath:raze respath,"/logs/";system "mkdir ",logpath];
  .proc.createlog[logpath;testname;`$ssr[string .z.p;"[D.:]";"_"];0b];
  };

// Write test results to disk
.k4.writeres:{[res;err;respath;rtime;testname]
  // Generate file names anc create them if they don't exist
  resfile:"results_",(raze "." vs string .z.d),".csv";
  errfile:"errors_",(raze "." vs string .z.d),".csv";
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

// Set up results and logging directories
if[.k4.savetodisk & (last "/" vs .z.X 1) like "torq*";
  args:({x,string[.z.d],"/"};{`$last "/" vs x}) @' first each (.Q.opt .z.x)[`results`test];
  .[.k4.setup;args;{.lg.e[`test;"Error: ",x]}]
  ];

// Load & run tests, show results
KUltd each hsym`$.proc.params[`test];
KUrt[];

show "k4unit Test Results"
show KUTR
show "k4unit Test Errors"
show KUerr

// Log any outstanding errors in run, true or fail tests
errtab:`action`err`code`file xcols update err:`unknown from select action,code,file from KUTR where not valid;
.lg.e[`KUexecerr;] each KUerrparseinner .' value each errtab;

// If enabled and if this is a TorQ process, write results to disk
if[.k4.savetodisk & (last "/" vs .z.X 1) like "torq*";
  args:(KUTR;KUerr),({x,string[.z.d],"/"};{"P"$x};{`$last "/" vs x}) @' first each (.Q.opt .z.x)[`results`runtime`test];
  .[.k4.writeres;args;{.lg.e[`test;"Error: ",x]}];
  exit 0
  ];
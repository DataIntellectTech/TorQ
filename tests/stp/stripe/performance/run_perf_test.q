// Set up results and logging directories
.k4.setup:{[respath;testname]
  .os.md each (respath;rp:respath,string[.z.d],"/");
  if[not 11h=type key hsym `$logpath:raze rp,"/logs/";.os.md logpath];
  .proc.createlog[logpath;testname;`$ssr[string .z.p;"[D.:]";"_"];0b];
  };

// Generate results files and handles to them
.k4.handlesandfiles:{[dir;filename]
  h:hopen f:hsym `$dir,"/",filename;
  if[not hcount f;.lg.o[`writeres;"Creating file ",1_string f]];
  :(h;f)
  };

// Write test results to disk
.k4.writeres:{[res;err;respath;rtime;testname]
  // Create results directories and files and open handles, timestamp test results
  .os.md each (respath;rp:respath,string[.z.d],"/");
  hf:.k4.handlesandfiles[rp;] each ("results_";"failures_") ,\: (raze "." vs string .z.d),".csv";
  res:`runtime xcols update runtime:first rtime from delete timestamp from res;
  err:`runtime xcols update runtime:first rtime from delete timestamp from err;

  // If file is empty, append full results/error table to it, if not, drop the header row before appending
  .lg.o[testname;"Writing ",string[count KUTR]," results rows and ",string[count KUerr]," error rows"];
  {neg[x] $[hcount y;1;0]_csv 0: z} .' hf ,' enlist each (res;err);
  hclose each first each hf;
  };

//-- SCRIPT START --//

clargs:(getenv[`KDBTESTS],"/stp/results/stripe/performance/";`timestamp$();`stripe_performance);

// Set up results and logging directories if not in debug mode and results directory defined
.[.k4.setup;clargs 0 2;{.lg.e[`test;"Error: ",x]}];

// Load & run tests, show results
KUltd each hsym`$getenv[`perfpath];
KUrt[];
show each ("k4unit Test Results";KUTR;"k4unit Test Errors";KUerr);

// Write results to disk
.[.k4.writeres;(KUTR;KUerr),clargs;{.lg.e[`test;"Error: ",x]}];
if[not `debug in key .Q.opt .z.x;exit count KUerr];
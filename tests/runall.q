// Define run-all function
.k4.runall:{[run;res]
  // Find all the run scripts, generate strings and execute
  rundirs:dirs where `run.sh in' key each dirs:.Q.dd[run;] each key run;
  runtime:string .z.p;
  command:{1_string[x],"/run.sh -r ",y," -wq"}[;runtime] each rundirs;
  {show "Executing ",x;system x} each command;

  // Load in results and error CSVs
  files:.Q.dd[resdir;] each f where (f:key resdir:.Q.dd[res;`$string .z.d]) like "*.csv";
  errors:0:[("PSIISSBSJJBBBI";enlist csv);first files];
  results:0:[("PSIISSBSJJBBBBI";enlist csv);last files];

  // Get errors from most recent log files and set results to local variables
  reclogs:.Q.dd[logdir;] each l where not (l:key logdir:.Q.dd[resdir;`logs]) like "*",ssr[string .z.d;".";"_"],"*";
  logerr:err!read0 each err:reclogs where reclogs like "*err*";
  `results`fails`errors set' (results;errors;logerr);
  };

// Only execute function if the necessary flags are passed in
if[all `rundir`resdir in key args:.Q.opt .z.x;
  .k4.runall . hsym each `$first each args[`rundir`resdir];
  show each ("Test results:";results;"Test failures:";fails;"Logged errors:";errors)
  ];
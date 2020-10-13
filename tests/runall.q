// Pass in two flags: rundir and resdir
run:first hsym `$(.Q.opt .z.x)`rundir;
res:first hsym `$(.Q.opt .z.x)`resdir;

// Find all the run scripts, generate strings and execute
rundirs:dirs where `run.sh in' key each dirs:.Q.dd[run;] each key run;
runtime:string .z.p;
command:{1_string[x],"/run.sh -r ",y}[;runtime] each rundirs;
{show "Executing ",x;system x} each command ,\: " -wq";

// Load in results and error CSVs
files:.Q.dd[resdir;] each f where (f:key resdir:.Q.dd[res;`$string .z.d]) like "*.csv"
errors:0:[("PSIISSBSJJBBBI";enlist csv);first files];
results:0:[("PSIISSBSJJBBBBI";enlist csv);last files];

// Get errors from most recent log files
reclogs:.Q.dd[logdir;] each l where not (l:key logdir:.Q.dd[resdir;`logs]) like "*[0-9]*";
logerr:err!read0 each err:reclogs where reclogs like "*err*";

// Display output
show each ("Test results:";results;"Test errors:";errors;"Logged errors:";logerr);
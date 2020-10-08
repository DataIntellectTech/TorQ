// Get all directories containing a run.sh script, construct shell commands, run with the -q command
rundirs:(key `:.) where `run.sh in' key each hsym each key `:.;
runtime:string .z.p;
command:{"./",string[x],"/run.sh -r ",y}[;runtime] each rundirs;
{show "Executing ",x;system x} each command ,\: " -q";

// Load in results and error CSVs
files:.Q.dd[resdir;] each f where (f:key resdir:.Q.dd[`:results;`$string .z.d]) like "*.csv";
errors:0:[("PSIISSBSJJBBBI";enlist csv);first files];
results:0:[("PSIISSBSJJBBBBI";enlist csv);last files];

// Get errors from most recent log files
reclogs:.Q.dd[logdir;] each l where not (l:key logdir:.Q.dd[resdir;`logs]) like "*[0-9]*";
logerr:err!read0 each err:reclogs where reclogs like "*err*";

// Display output
show each ("Test results:";results;"Test errors:";errors;"Logged errors:";logerr);
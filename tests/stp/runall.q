// Get all directories containing a run.sh script, construct and run shell commands
rundirs:(key `:.) where `run.sh in' key each hsym each key `:.;
command:{"./",string[x],"/run.sh"} each rundirs;
{show "Executing ",x;system x} each command;

// Load in results and error CSVs
results:0:[("SIISSBSJJBBBBP";enlist csv);`$getenv[`KDBTESTS],"/stp/results/results_",(raze "." vs string .z.d),".csv"];
errors:0:[("SIISSBSJJBBBP";enlist csv);`$getenv[`KDBTESTS],"/stp/results/errors_",(raze "." vs string .z.d),".csv"];

// Display output
system "c 25 160";
show each ("Test results:";results;"Test errors:";errors);
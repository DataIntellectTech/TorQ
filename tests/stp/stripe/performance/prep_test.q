// Load timer functions
system"l ",getenv[`KDBCODE],"/common/timer.q"

// Load specific test files
system"l ",getenv[`KDBTESTS],"/k4unit.q"
system"l ",getenv[`KDBTESTS],"/helperfunctions.q"
system"l ",getenv[`testpath],"/settings.q"

// Initialize stp first
init[]
// Prevent re-initialization
init:{}

// Get connection management set up
.servers.startup[]

\d .timer

starttests:{[]
  // Check if ready to start tests - retry connection if not ready
  if[(exec any null w from .servers.SERVERS where proctype=`rdb)|(not`upd in key`.u)|(not`upd in key`.stp)|not`nextendUTC in key`.stplg;.servers.retry[]];
  // Check again after retrying connection - return if still not ready
  if[(exec any null w from .servers.SERVERS where proctype=`rdb)|(not`upd in key`.u)|(not`upd in key`.stp)|not`nextendUTC in key`.stplg;:()];

  // Once connection ready - clear timer and start tests
  remove[1];
  system"l ",getenv[`perfpath],"/run_perf_test.q";
  }

// Check every 5s
repeat[.proc.cp[];.proc.cp[]+0D00:01;0D00:00:05;(starttests;`);"Check for rdbs connections & start tests once all connected"]
.z.ts:run
\t 1000
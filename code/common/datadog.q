// DATADOG CHECKS

//Create datadog namespace
\d .dg

//Functions are set to return 1b or 0b based on the health of the service.
//Default check returns 1b from each process to indicate process is up and can be queried.
//These checks run every time crontab/timer is run.

handlers:(`$())!()

isok:{$[.proc.proctype in key .dg.handlers;.dg.handlers .proc.proctype;1b]}

//Option to override default .lg.ext functionality to send error and warning events to datadog
init:{[]
  .lg.ext:{[loglevel;proctype;proc;id;message;dict]
  if[loglevel in `ERR`WARN;.dg.sendEvent[string proc;message;string proctype;]$[loglevel=`ERR;"error";"warning"]]}
 }

\d .

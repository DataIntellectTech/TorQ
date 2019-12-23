// DATADOG CHECKS

//Create datadog namespace
\d .dg

ddconfigfile:@[value;`ddconfigfile;hsym first .proc.getconfigfile"ddconfig.txt"]

//sets dogstatsd_port to the port defined by ddconfigfile
$[`ddconfig.txt in key hsym `$getenv[`KDBAPPCONFIG];value each read0 ddconfigfile;dogstatsd_port:8125]

//Functions are set to return 1b or 0b based on the health of the service.
//Default check returns 1b from each process to indicate process is up and can be queried.
//These checks run every time crontab/timer is run.

handlers:(`$())!()

is_ok:{[x]
  f:$[@[{[x].proc.proctype in key .dg.handlers};`;0b];
    .dg.handlers[.proc.proctype];
    .dg.default_is_ok];
  @[f;`;0b]
 }

default_is_ok:{[x]1b}

//functions to send metrics and events to datadog from TorQ processes
sendMetric:{[metric_name;metric_value] system"bash -c \"echo  -n '",metric_name,":",(string metric_value),"|g|#shell' > /dev/udp/127.0.0.1/",(string dogstatsd_port),"\"";}

.dg.sendEvent:{[event_title;event_text;tags;alert_type]
  system"event_title=",event_title,"; event_text=","\"",event_text,"\"","; tags=","\"#",$[0h=type tags;","sv tags;tags],"\"",";alert_type=",alert_type,"; ","echo \"_e{${#event_title},${#event_text}}:$event_title|$event_text|#$tags|t:$alert_type\" |nc -4u -w0 127.0.0.1 ",string dogstatsd_port;
 }

//Option to override default .lg.ext functionality to send error and warning events to datadog
init:{[]
  .lg.ext:{[loglevel;proctype;proc;id;message;dict]
  if[loglevel in `ERR`WARN;.dg.sendEvent[string proc;message;string proctype;]$[loglevel=`ERR;"error";"warning"]]}
 }

\d .

// DATADOG CHECKS

//Create datadog namespace
\d .dg

ddconfigfile:@[value;ddconfigfile;hsym `$getenv[`KDBAPPCONFIG],"/ddconfig.txt"]

//sets dogstatsd_port to the port defined by ddconfigfile
value first read0 ddconfigfile

//Functions are set to return 1b or 0b based on the health of the service.
//Default check returns 1b from each process to indicate process is up and can be queried.
//These checks run every time crontab/timer is run.

handlers:(`symbol$())!()

is_ok:{[x]
        f:$[@[{[x].proc.proctype in key .dg.handlers};`;0b];
                .dg.handlers[.proc.proctype];
                .dg.default_is_ok];
        @[f;`;0b]
        }

default_is_ok:{[x]1b}

//functions to send metrics and events to datadog from TorQ processes
sendMetric:{[metric_name;metric_value] system"echo -n ","\"",metric_name,":",(string metric_value),"|g|","#shell \" | nc -4u -w0 127.0.0.1 ",$[count .dg.dogstatsd_port;string .dg.dogstatsd_port;"8127"];};

sendEvent:{[event_title;event_text;tags;alert_type] system"event_title=",event_title,"; event_text=",event_text,"; tags=",tags,";alert_type=",alert_type,"; ","echo \"_e{${#event_title},${#event_text}}:$event_title|$event_text|#$tags|t:$alert_type\" |nc -4u -w0 127.0.0.1 ",$[count .dg.dogstatsd_port;string .dg.dogstatsd_port;"8127"];}

\d .

//override default .lg.ext functionality to send error and warning events to datadog
.lg.ext:{[loglevel;proctype;proc;id;message;dict]
 if[loglevel in `ERR`WARN;.dg.sendEvent[string proc;"\"",message,"\"";string proctype;]$[loglevel=`ERR;"error";"warning"]]}

// DATADOG CHECKS

//Create datadog namespace
\d .dg

//define dogstatsd_port
dogstatsd_port:getenv[`DOGSTATSD_PORT]

//Functions are set to return 1b or 0b based on the health of the service.
//Default check returns 1b from each process to indicate process is up and can be queried.
//These checks run every time crontab/timer is run.

handlers:(`$())!()

isok:{$[.proc.proctype in key .dg.handlers;.dg.handlers .proc.proctype;1b]}

//define sendmetric and sendevent functions
.dg.sendevent:$[.z.o like "l*";{[event_title;event_text;tags;alert_type] system"event_title=",event_title,"; event_text=","\"",event_text,"\"","; tags=","\"#",$[0h=type tags;","sv tags;tags],"\"",";alert_type=",alert_type,"; ","echo \"_e{${#event_title},${#event_text}}:$event_title|$event_text|#$tags|t:$alert_type\" |nc -4u -w0 127.0.0.1 ",dogstatsd_port; };"Currently only linux operating systems are supported to send events"]

.dg.sendmetric:$[.z.o like "l*";{[metric_name;metric_value] system"bash -c \"echo  -n '",metric_name,":",(string metric_value),"|g|#shell' > /dev/udp/127.0.0.1/",dogstatsd_port,"\"";};"Currently only linux operating systems are supported to send metrics"]

//Option to override default .lg.ext functionality to send error and warning events to datadog
init:{[]
  .lg.ext:{[olddef;loglevel;proctype;proc;id;message;dict]
  olddef[loglevel;proctype;proc;id;message;dict];
  if[loglevel in `ERR`WARN;.dg.sendevent[string proc;message;string proctype;]$[loglevel=`ERR;"error";"warning"]]}[@[value;`.lg.ext;{{[loglevel;proctype;proc;id;message;dict]}}]]
 }

\d .

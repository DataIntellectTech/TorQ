// DATADOG CHECKS

//Create datadog namespace
\d .dg

//default to disabled - .lg.ext will not be overwritten
enabled:@[value;`enabled;0b]

//default to disabled - datadog agent used
webreq:@[value;`webreq;0b] 

//define dogstatsd_port
dogstatsd_port:@[value;`dogstatsd_port;getenv[`DOGSTATSD_PORT]]

//define dogstatsd_apikey
dogstatsd_apikey:@[value;`dogstatsd_apikey;getenv[`DOGSTATSD_APIKEY]]

//define dogstatsd_url
dogstatsd_url:":https://api.datadoghq.com/api/v1/"


//Functions are set to return 1b or 0b based on the health of the process
//Default check (isok) returns 1b from each process to indicate process is up and can be queried.

handlers:(`$())!()

isok:{$[.proc.proctype in key .dg.handlers;.dg.handlers .proc.proctype;1b]}

//define sendmetric and sendevent functions using datadog agent
.dg.sendevent:{[event_title;event_text;tags;alert_type] 
  $[.z.o like "l*";
    system"event_title=",event_title,"; event_text=","\"",event_text,"\"","; tags=","\"#",$[0h=type tags;","sv tags;tags],"\"",";alert_type=",alert_type,"; ","echo \"_e{${#event_title},${#event_text}}:$event_title|$event_text|#$tags|t:$alert_type\" |nc -4u -w0 127.0.0.1 ",dogstatsd_port;
    .lg.w[`sendevent;"Currently only linux operating systems are supported to send events"]]
  }

.dg.sendmetric:{[metric_name;metric_value]
  $[.z.o like "l*";
    system"bash -c \"echo  -n '",metric_name,":",(string metric_value),"|g|#shell' > /dev/udp/127.0.0.1/",dogstatsd_port,"\"";
    .lg.w[`sendmetric;"Currently only linux operating systems are supported to send metrics"]]
  }

//define sendmetric and sendevent functions using web request
.dg.sendevent_webreq:{[event_title;event_text;tags;alert_type]
  url:`$dogstatsd_url,"events?api_key=",dogstatsd_apikey;
  .Q.hp[url;.h.ty`json]
    .j.j`title`text`priority`tags`alert_type!(event_title;event_text;"normal";$[0h=type tags;","sv tags;tags];alert_type)
  }

.dg.sendmetric_webreq:{[metric_name;metric_value]
  url:`$dogstatsd_url,"series?api_key=",dogstatsd_apikey;
  unix_time:floor((`long$.z.p)-1970.01.01D00:00)%1e9;
  .Q.hp[url;.h.ty`json]
    .j.j (enlist `series)!enlist(enlist (`metric`points`host`tags!(metric_name;enlist (unix_time;metric_value);.z.h;"shell")))
  }

//Option to override default .lg.ext functionality to send error and warning events to datadog
enablelogging:{[]
  .lg.ext:{[olddef;loglevel;proctype;proc;id;message;dict]
  olddef[loglevel;proctype;proc;id;message;dict];
  if[loglevel in `ERR`WARN;.dg.sendevent[string proc;message;string proctype;]$[loglevel=`ERR;"error";"warning"]]}[@[value;`.lg.ext;{{[loglevel;proctype;proc;id;message;dict]}}]]
 }

\d .

if[.dg.enabled;.dg.enablelogging[]]

if[.dg.webreq;.dg.sendevent:.dg.sendevent_webreq;.dg.sendmetric:.dg.sendmetric_webreq]

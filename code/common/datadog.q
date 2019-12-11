// DATADOG CHECKS

//Create datadog namespace
\d .dg

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

sendMetric:{[metric_name;metric_value] system getenv[`TORQHOME],"/datadog/sendToDatadog.sh ",(string metric_value)," ",metric_name;};
//sendEvent:{[event_title;event_text] system getenv[`TORQHOME],"/datadog/sendEventToDatadog.sh ",event_title," ",event_text;};
sendEvent:{[event_title;event_text;tags;alert_type] system getenv[`TORQHOME],"/datadog/sendEventToDatadog.sh ",event_title," ",event_text," ",tags," ",alert_type;}

\d .

//override default .lg.ext functionality to send error and warning events to datadog
.lg.ext:{[loglevel;proctype;proc;id;message;dict]
 if[loglevel in `ERR`WARN;.dg.sendEvent[string proc;"\"",message,"\"";string proctype;]$[loglevel=`ERR;"error";"warning"]]}

//DATADOG CHECKS
//Script for running checks manually/via crontab
//Makes dictionary of defaults and uses .Q.opt to refer to command values passed by its key.
o:.Q.def[`user`pass`timeout`init`noexit!(`admin;`admin;100;1b;0b);.Q.opt[.z.x]]

// Send To Datadog function - takes a non string value and a stringed name.
//Will send the value received (1 or 0) and the process name (hdb etc)
//functions to send metrics and events to datadog from TorQ processes, error check for systems other than linux
.dg.sendMetric:$[any `l32`l64 in .z.o;{[metric_name;metric_value] system 0N!"bash -c \"echo  -n '",metric_name,":",(string metric_value),"|g|#shell' > /dev/udp/127.0.0.1/",(string dogstatsd_port),"\"";};"Currently only linux operating systems are supported to send metrics"]

.dg.sendEvent:$[any `l32`l64 in .z.o;{[event_title;event_text;tags;alert_type] system"event_title=",event_title,"; event_text=","\"",event_text,"\"","; tags=","\"#",$[0h=type tags;","sv tags;tags],"\"",";alert_type=",alert_type,"; ","echo \"_e{${#event_title},${#event_text}}:$event_title|$event_text|#$tags|t:$alert_type\" |nc -4u -w0 127.0.0.1 ",string dogstatsd_port; };"Currently only linux operating systems are supported to send events"]

//Creates the torq summary table without the pipes
.dg.getprocess:{[x]
  {[x]flip (((`TIME`PROCESS`STATUS`PID`PORT!"TSSII")key[x]))$x} {[x] {[x](`$x[;0])! flip 1_ flip[x]} trim ("*****"; "|")0:x} system "./torq.sh summary"
 }

//Names of processes to be monitored to be edited depending on monitoring needs
.dg.monitorprocess:()


//Open port to process and sends check for each is_ok function
.dg.sendcheck:{[o;x]
  h:hopen[(hsym `$":" sv string[(`localhost;x[`PORT];o[`user];o[`pass])];o[`timeout])];
  :h(`.dg.is_ok;`)
 }
//Creates name for the event (how it is found on datadog metric)
.dg.createeventname:{[x]"_" sv string (`process;x[`PROCESS];`check)}

//state either 1b or 0b (with error trap) calling sendMetric.
.dg.check:{[x;o]state:.[.dg.sendcheck;(o;x);{[x]0b}];.dg.sendMetric[.dg.createeventname[x];state]}

//Checks each of the processes on the monitor list
.dg.checkall:{[x;o].dg.check[;o] each x}

//Retrieves the processes to be monitored with summary data. 
.dg.init:{[x]
  .dg.allprocesslist:.dg.getprocess[];
  .dg.monitoredprocesslist:select from .dg.allprocesslist where any PROCESS like/:{[x]string[x],"*"}'[.dg.monitorprocess];	
  .dg.checkall[.dg $[count .dg.monitorprocess;`monitoredprocesslist;`allprocesslist]]o
 }

//if init is set to true run init
if[o`init;@[.dg.init;`;1b]]
//If the noexit is set to 0b then exit
if[not o[`noexit];exit[0]]

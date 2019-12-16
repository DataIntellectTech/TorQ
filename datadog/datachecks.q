//DATADOG CHECKS
//Script for running checks manually/via crontab
//Makes dictionary of defaults and uses .Q.opt to refer to command values passed by its key.
o:.Q.def[`user`pass`timeout`init`noexit!(`admin;`admin;100;1b;0b);.Q.opt[.z.x]]

ddconfigfile:hsym `$getenv[`KDBAPPCONFIG],"/ddconfig.txt"
value first read0 ddconfigfile

// Send To Datadog function - takes a non string value and a stringed name.
//Will send the value received (1 or 0) and the process name (hdb etc)
.datadog.sendMetric:{[metric_name;metric_value] system"echo -n ","\"",metric_name,":",(string metric_value),"|g|","#shell \" | nc -4u -w0 127.0.0.1 ",$[count dogstatsd_port;string dogstatsd_port;"8125"];};

.datadog.sendEvent:{[event_title;event_text;tags;alert_type] system "event_title=",event_title,"; event_text=",event_text,"; tags=",tags,";alert_type=",alert_type,"; ","echo \"_e{${#event_title},${#event_text}}:$event_title|$event_text|#$tags|t:$alert_type\" |nc -4u -w0 127.0.0.1 ",$[count dogstatsd_port;string dogstatsd_port;"8125"];}

//Creates the torq summary table without the pipes
.datadog.getprocess:{[x]
        {[x]flip (((`TIME`PROCESS`STATUS`PID`PORT!"TSSII")key[x]))$x} {[x] {[x](`$x[;0])! flip 1_ flip[x]} trim ("*****"; "|")0:x} system "./torq.sh summary"
 }

//Names of processes to be monitored to be edited depending on monitoring needs
//.datadog.monitorprocess:()
.datadog.monitorprocess:`tickerplant`hdb`wdb`rdb

//Open port to process and sends check for each is_ok function
.datadog.sendcheck:{[o;x]
        h:hopen[(hsym `$":" sv string[(`localhost;x[`PORT];o[`user];o[`pass])];o[`timeout])];
        :h(`.dg.is_ok;`)
        }
//Creates name for the event (how it is found on datadog metric)
.datadog.createeventname:{[x]"_" sv string (`process;x[`PROCESS];`check)}

//state either 1b or 0b (with error trap) calling sendMetric.
.datadog.check:{[x;o]state:.[.datadog.sendcheck;(o;x);{[x]0b}];.datadog.sendMetric[.datadog.createeventname[x];state]}

//Checks each of the processes on the monitor list
.datadog.checkall:{[x;o].datadog.check[;o] each x}

//Retrieves the processes to be monitored with summary data. 
.datadog.init:{[x]
        .datadog.allprocesslist:.datadog.getprocess[];
	.datadog.monitoredprocesslist:select from .datadog.allprocesslist where any PROCESS like/:{[x]string[x],"*"}'[.datadog.monitorprocess];	
        $[count .datadog.monitorprocess;.datadog.checkall[.datadog.monitoredprocesslist;o];.datadog.checkall[.datadog.allprocesslist;o]]
        }

//if init is set to true run init
if[o[`init];@[.datadog.init;`;1]]
//If the noexit is set to 0b then exit
if[not o[`noexit];exit[0]]

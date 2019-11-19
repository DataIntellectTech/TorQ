//DATADOG CHECKS
//Makes dictionary of defaults and uses .Q.opt to refer to command values passed by its key.
o:.Q.def[`user`pass`timeout`init`noexit!(`admin;`admin;100;1b;0b);.Q.opt[.z.x]]

// Send To Datadog function - takes a non string value and a stringed name.
//Will send the value received (1 or 0) and the process name (hdb etc)
.datadog.sendMetric:{[metric_name;metric_value] system 0N!"${TORQHOME}/datadog/sendToDatadog.sh ",(string metric_value)," ",metric_name;};
.datadog.sendEvent:{[event_title;event_text] system"${TORQHOME}/datadog/sendEventToDatadog.sh ",event_title," ",event_text;};

//Creates the torq summary table without the pipes
.datadog.getprocess:{[x]
        {[x]flip (((`TIME`PROCESS`STATUS`PID`PORT!"TSSII")key[x]))$x} {[x] {[x](`$x[;0])! flip 1_ flip[x]} trim ("*****"; "|")0:x} system "${TORQHOME}/torq.sh summary"
        }
//Names of processes to be monitored to be edited depending on monitoring needs
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
        .datadog.checkall[.datadog.monitoredprocesslist;o];
        }
//if init is set to true run init
if[o[`init];@[.datadog.init;`;1]]
//If the noexit is set to 0b then exit
if[not o[`noexit];exit[0]]

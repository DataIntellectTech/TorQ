//DATADOG CHECKS
o:.Q.def[`user`pass`timeout`init`noexit!(`admin;`admin;100;1b;0b);.Q.opt[.z.x]]

// Sent To Datadog function - takes a non string value and a stringed name
.datadog.sendMetric:{[metric_name;metric_value] system 0N!"~/torqdog/deploy/datadog/sendToDatadog.sh ",(string metric_value)," ",metric_name;};
.datadog.sendEvent:{[event_title;event_text] system"~/torqdog/deploy/datadog/sendEventToDatadog.sh ",event_title," ",event_text;};

.datadog.getprocess:{[x]
        {[x]flip (((`TIME`PROCESS`STATUS`PID`PORT!"TSSII")key[x]))$x} {[x] {[x](`$x[;0])! flip 1_ flip[x]} trim ("*****"; "|")0:x} system "~/torqdog/deploy/torq.sh summary"
        }

.datadog.monitorprocess:`tickerplant`discovery`hdb`wdb`housekeeping

.datadog.sendcheck:{[o;x]
        h:hopen[(hsym `$":" sv string[(`localhost;x[`PORT];o[`user];o[`pass])];o[`timeout])];
        :h(`.dg.is_ok;`)
        }

.datadog.createeventname:{[x]"_" sv string (`process;x[`PROCESS];`check)}

.datadog.check:{[x;o]state:.[.datadog.sendcheck;(o;x);{[x]0b}];.datadog.sendMetric[.datadog.createeventname[x];state]}

.datadog.checkall:{[x;o].datadog.check[;o] each x}

.datadog.init:{[x]
        .datadog.allprocesslist:.datadog.getprocess[];
        .datadog.monitoredprocesslist:select from .datadog.allprocesslist where any PROCESS like/:{[x]string[x],"*"}'[.datadog.monitorprocess];
        .datadog.checkall[.datadog.monitoredprocesslist;o];
        }
if[o[`init];@[.datadog.init;`;1]]

if[not o[`noexit];exit[0]]

//#.datadog.quotevolume:{[h]
//# //t:h"exec count i from mdquote_custom where time>.z.P-00:05:00";
//#.datadog.sendMetric["DQ.QUOTEVOL";1];

//# };

//#rdb_h:@[hopen;`::5502:rdb:pass;`err];

//#@[.datadog.quotevolume;rdb_h;`err];

//#hclose rdb_h;

//#exit 0;

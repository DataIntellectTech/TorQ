/Add to API functions for process

\d .api

//addcheck

//copyconfig
add[`copyconfig;1b;"Copy row of config into checkconfig with new process";"[int:check id to be copied;symbol: new process name]";"table with additional row"];

//disablecheck
add[`disablecheck;1b;"Disable check until enabled again";"[list of int:check id to be disabled]";"table with relevant checks disabled"];

//enablecheck
add[`enablecheck;1b;"Enable checks";"[list of int: check id to be enabled]";"table with relevant checks enabled"];

//checkruntime
add[`checkruntime;1b;"Check process has not been running over next alloted runtime,amend checkstatus accordingly";"[timespan:threshold age of check";"amended checkstatus table"]

//timecheck
add[`timecheck;1b;"Check if median loadtime is less than specific value";"[timespan:threshold median time value]";"table with boolean value returning true if median loadtime lower than threshold"];

//updateconfig
add[`updateconfig;1b;"Add new parameter config to checkconfig table";"[int:checkid to be changed;symbol:parameter key;undefined:new parameter value]";"checkconfig table with new config added"];

//updateconfigfammet
add[`updateconfigfammet;1b;"Add new parameter config to checkconfig table";"[symbol:family;symbol:metric;symbol:parameter key;undefined:new parameter value";"checkconfig table with new config added"];

//forceconfig
add[`forceconfig;1b;"Force new config parameter over top of existing config without checking types";"[int:checkid;dictionary:new config"];

//currentstatus
add[`currentstatus;1b;"Return only current information for each check";"[list of int: checkids to be returned]";"table of checks"];

//statusbyfam
add[`statusbyfam;1b;"Return checkstatus table ordered by status then timerstatus";"[symbol:name of family of checks]";"table ordered by status and timerstatus"];

//cleartracker
add[`cleartracker;1b;"Delete rows older than certain amount of time from checktracker";"[timespan:maximum age of check to be kept]";"checktracker table with removed rows"]


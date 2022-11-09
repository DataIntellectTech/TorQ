\d .queries

// Create a queries table to record query information
queries:@[value;`queries;([]starttime:`timestamp$();endtime:`timestamp$();runtime:`timespan$();user:`symbol$();ip:`int$();prochost:`symbol$();procname:`symbol$();proctype:`symbol$();query:();success:`boolean$())] 

logquery:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;1b); result}

logqueryerror:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;0b); 'result}

.z.pg:{cmd:x; .queries.logquery[.proc.cp[];@[value;x;.queries.logqueryerror[.proc.cp[];;cmd;startp]];cmd;startp:.proc.cp[]]}

.z.ps:{cmd:x; .queries.logquery[.proc.cp[];@[value;x;.queries.logqueryerror[.proc.cp[];;cmd;startp]];cmd;startp:.proc.cp[]]}


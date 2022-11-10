\d .queries

// Create a queries table to record query information
queries:@[value;`queries;([]starttime:`timestamp$();endtime:`timestamp$();runtime:`long$();user:`symbol$();ip:`int$();prochost:`symbol$();procname:`symbol$();proctype:`symbol$();query:();success:`boolean$())]

logquery:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;1b); result}

logqueryerror:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;0b); 'result}

.z.pg:{.queries.logquery[.proc.cp[];@[x;y;.queries.logqueryerror[.proc.cp[];;y;startp]];y;startp:.proc.cp[]]}.z.pg

.z.ps:{.queries.logquery[.proc.cp[];@[x;y;.queries.logqueryerror[.proc.cp[];;y;startp]];y;startp:.proc.cp[]]}.z.ps

\d .queries

//flags and variables
enabled:@[value;`enabled;1b]
ignore:@[value;`ignore;1b]
ignorelist:@[value;`ignorelist;(`upd;"upd")]

//table schema
queries:@[value;`queries;([]starttime:`timestamp$();endtime:`long$();runtime:`long$();user:`symbol$();ip:`int$();prochost:`symbol$();procname:`symbol$();proctype:`symbol$();query:();success:`boolean$())]

//upsert successful query
logquery:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;1b); result}
//upsert failed query
logqueryerror:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;0b); 'result}

//customising .z.pg/ps
p1:{.queries.logquery[.proc.cp[];@[x;y;.queries.logqueryerror[.proc.cp[];;y;startp]];y;startp:.proc.cp[]]}
//added for ignoring messages
p2:{if[ignore; if[0h=type y;if[any first[y]~/:ignorelist; :x@y]]]; p1[x;y]}

if[enabled; .z.pg:(p1).z.pg; .z.ps:(p2).z.ps;];

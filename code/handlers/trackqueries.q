\d .queries

//flags and variables
enabled:@[value;`enabled;1b]
ignore:@[value;`ignore;1b]
ignorelist:@[value;`ignorelist;(`upd;"upd")]
settimer:@[value;`settimer;0D00:00:10]
threshold:@[value;`threshold;50]

//table schema
queries:@[value;`queries;([]starttime:`timestamp$();endtime:`timestamp$();runtime:`long$();user:`symbol$();ip:`int$();prochost:`symbol$();procname:`symbol$();proctype:`symbol$();query:();success:`boolean$())]

//upsert successful query
logquery:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;1b); result}
//upsert failed query
logqueryerror:{[endp;result;arg;startp] `.queries.queries upsert (startp;endp;`long$.001*endp-startp;.z.u;.z.a;.z.h;.proc.procname;.proc.proctype;arg;0b); 'result}

//customising .z.pg/ps
p1:{.queries.logquery[.proc.cp[];@[x;y;.queries.logqueryerror[.proc.cp[];;y;startp]];y;startp:.proc.cp[]]}
//added for ignoring messages
p2:{if[ignore; if[0h=type y;if[any first[y]~/:ignorelist; :x@y]]]; p1[x;y]}

if[enabled; .z.pg:(p1).z.pg; .z.ps:(p2).z.ps;];

savedown:{[dir;tabname;pt]
 pth:` sv .Q.par[dir;pt;tabname],`;
 err:{[e].lg.e[`savedata;"Failed to save client query data to disk : ",e];'e};
 .[upsert;(pth;.Q.en[dir;.save.manipulate[tabname;.queries.queries]]);err];
 .queries.queries:0#.queries.queries;
 };

rowcheck:{[dir;tabname;pt]
 countvalue:count .queries.queries;
 if[countvalue > .queries.threshold; savedown[dir;tabname;pt]];
 }

settimers:{
 .timer.repeat[.proc.cp[];0Wp;.queries.settimer;(`.queries.rowcheck;`:data/hdb;`clientqueries;.z.d);"save client query data to disk"];
 .timer.repeat[.proc.cp[];0Wp;0D00:01:00;(`.queries.savedown;`:data/hdb;`clientqueries;.z.d);"save client query data to disk"];
 }

if[enabled; .queries.settimers[];];
